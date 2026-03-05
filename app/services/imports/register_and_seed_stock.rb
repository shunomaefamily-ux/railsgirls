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


        raise ArgumentError, "このQRはすでに登録されています" if @import.person_id.present?
        @import.update!(person: @person)

        extracted = Jahis::Tc08::Extractor.new(raw_text: @import.raw_text).call
        unless extracted.version == "JAHISTC08"
          raise ArgumentError, "JAHISTC08形式ではありません（手入力で登録してください）"
        end
        base_date = extracted.base_date || Date.today

        extracted.drugs.each_with_index do |drug_hash, i|
          drug = DrugProduct.find_or_create_by!(display_name: drug_hash[:display_name]) do |dp|
            dp.is_temporary = true if dp.respond_to?(:is_temporary=)
          end

          item = MedicationItem.find_or_create_by!(person: @person, drug_product: drug) do |mi|
            mi.active = true
          end

          expires_on = @expires_on || (base_date + drug.shelf_life_days_or_default)

          qty = @quantities.present? ? @quantities[i.to_s].to_i : @quantity

          item.medication_lots.create!(
            base_date: base_date,
            shelf_life_days: drug.shelf_life_days_or_default,
            expires_on: expires_on,
            quantity_initial: qty,
            quantity_remaining: qty
          )
        end
      end
    end
  end
end