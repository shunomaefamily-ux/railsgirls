require "csv"

module Imports
  class RegisterAndSeedStock
    def initialize(import:, person:, quantity:, quantities: nil, expires_on: nil, usage_kind_by_index: nil, usage_slots_by_index: nil)
      @import = import
      @person = person
      @quantity = quantity.to_i
      @quantities = quantities&.to_h
      @expires_on = expires_on
      @usage_kind_by_index = usage_kind_by_index&.to_h || {}
      @usage_slots_by_index = usage_slots_by_index&.to_h || {}
    end

    def call!
      ActiveRecord::Base.transaction do
        ensure_not_registered!
        attach_person_to_import!

        extracted = extract_jahis!
        base_date = extracted.base_date || Date.current

        extracted.drugs.each_with_index do |drug_hash, index|
          drug = find_or_create_drug!(drug_hash)
          qty = resolve_quantity(index)
          lot_expires_on = resolve_expires_on(base_date, drug)
          usage_text = extract_usage_text(extracted, drug_hash)

          usage_kind = resolve_usage_kind(index, usage_text)
          usage_slots = resolve_usage_slots(index, usage_text, usage_kind)

          validate_usage!(drug_hash[:display_name], usage_kind, usage_slots)

          Stock::Register.call(
            person: @person,
            drug_product: drug,
            base_date: base_date,
            expires_on: lot_expires_on,
            quantity: qty,
            usage_text: usage_text,
            usage_kind: usage_kind,
            usage_slots: usage_slots
          )
        end
      end
    end

    private

    def ensure_not_registered!
      raise ArgumentError, "このQRはすでに登録されています" if @import.person_id.present?
    end

    def attach_person_to_import!
      @import.update!(person: @person)
    end

    def extract_jahis!
      raw_text = normalize_jahis_text(@import.raw_text)

      extracted =
        if raw_text.start_with?("JAHISTC08")
          Jahis::Tc08::Extractor.new(raw_text: raw_text).call
        elsif raw_text.start_with?("JAHISTC06")
          Jahis::Tc06::Extractor.new(raw_text: raw_text).call
        else
          nil
        end

      unless extracted
        raise ArgumentError, "JAHISTC06/08形式ではありません（手入力で登録してください）"
      end

      extracted
    end

    def normalize_jahis_text(text)
      text.to_s
          .sub("\uFEFF", "")
          .gsub("\r\n", "\n")
          .gsub("\r", "\n")
          .strip
    end

    def extract_usage_text(extracted, drug_hash)
      rp_no = drug_hash[:rp_no]
      raw_usage_lines = extracted.raw_usage_by_rp[rp_no]
      line = Array(raw_usage_lines).first.to_s
      return nil if line.blank?

      cols = CSV.parse_line(line, col_sep: ",")
      return nil if cols.blank?

      cols[2].to_s.strip.presence
    rescue CSV::MalformedCSVError
      nil
    end

    def find_or_create_drug!(drug_hash)
      DrugProduct.find_or_create_by!(display_name: drug_hash[:display_name]) do |drug_product|
        drug_product.is_temporary = true if drug_product.respond_to?(:is_temporary=)
      end
    end

    def resolve_quantity(index)
      if @quantities.present?
        @quantities[index.to_s].to_i
      else
        @quantity
      end
    end

    def resolve_expires_on(base_date, drug)
      @expires_on || (base_date + drug.shelf_life_days_or_default)
    end

    def resolve_usage_kind(index, usage_text)
      value = @usage_kind_by_index[index.to_s].to_s

      return value if %w[regular prn].include?(value)

      UsageSlotEstimator.call(usage_text).usage_kind
    end

    def resolve_usage_slots(index, usage_text, usage_kind)
      return [] if usage_kind == "prn"

      raw_slots = Array(@usage_slots_by_index[index.to_s]).reject(&:blank?)
      return raw_slots if raw_slots.present?

      UsageSlotEstimator.call(usage_text).usage_slots
    end

    def validate_usage!(drug_name, usage_kind, usage_slots)
      unless %w[regular prn].include?(usage_kind)
        raise ArgumentError, "#{drug_name} の飲み方区分を選択してください"
      end

      if usage_kind == "regular" && usage_slots.blank?
        raise ArgumentError, "#{drug_name} は朝・昼・晩を1つ以上選択してください"
      end

      invalid_slots = usage_slots - %w[morning noon evening]
      return if invalid_slots.empty?

      raise ArgumentError, "#{drug_name} の時間帯指定が不正です"
    end
  end
end