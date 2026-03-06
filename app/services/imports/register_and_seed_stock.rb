# app/services/imports/register_and_seed_stock.rb
module Imports
  class RegisterAndSeedStock
    def initialize(import:, person:, quantity:, quantities: nil, expires_on: nil)
      @import = import
      @person = person
      @quantity = quantity.to_i
      @quantities = quantities&.to_h
      @expires_on = expires_on
    end

    def call!
      ActiveRecord::Base.transaction do
        ensure_not_registered!
        attach_person_to_import!

        extracted = extract_tc08!
        base_date = extracted.base_date || Date.current

        extracted.drugs.each_with_index do |drug_hash, index|
          drug = find_or_create_drug!(drug_hash)
          qty = resolve_quantity(index)
          lot_expires_on = resolve_expires_on(base_date, drug)

          Stock::Register.call(
            person: @person,
            drug_product: drug,
            base_date: base_date,
            expires_on: lot_expires_on,
            quantity: qty
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

    def extract_tc08!
      extracted = Jahis::Tc08::Extractor.new(raw_text: @import.raw_text).call

      unless extracted.version == "JAHISTC08"
        raise ArgumentError, "JAHISTC08形式ではありません（手入力で登録してください）"
      end

      extracted
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
  end
end