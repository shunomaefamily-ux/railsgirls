# app/services/imports/register_and_seed_stock.rb
module Imports
  class RegisterAndSeedStock
    def initialize(import:, person:, quantity:, expires_on: nil)
      @import = import
      @person = person
      @quantity = quantity.to_i
      @expires_on = expires_on
    end

    def call!
      raise ArgumentError, "quantity must be >= 1" if @quantity < 1

      ActiveRecord::Base.transaction do
        # 二重登録の簡易ガード（好みで外してOK）
        if @import.person_id.present? && @import.person_id != @person.id
          raise ActiveRecord::RecordInvalid, "Import is already registered to another person"
        end

        @import.update!(person: @person)

        extracted = Jahis::Tc08::Extractor.new(raw_text: @import.raw_text).call
        unless extracted.version == "JAHISTC08"
          raise ArgumentError, "JAHISTC08形式ではありません（手入力で登録してください）"
        end
        base_date = extracted.base_date || Date.today

        extracted.drugs.each do |drug_hash|
          drug = DrugProduct.find_or_create_by!(display_name: drug_hash[:display_name]) do |dp|
            dp.is_temporary = true if dp.respond_to?(:is_temporary=)
          end

          item = MedicationItem.find_or_create_by!(person: @person, drug_product: drug) do |mi|
            mi.active = true
          end

          expires_on = @expires_on || (base_date + drug.shelf_life_days_or_default)

          item.medication_lots.create!(
            base_date: base_date,
            shelf_life_days: drug.shelf_life_days_or_default,
            expires_on: expires_on,
            quantity_initial: @quantity,
            quantity_remaining: @quantity
          )
        end
      end
    end
  end
end