# app/services/imports/register_and_seed_stock.rb
module Imports
  class RegisterAndSeedStock
    def initialize(import:, person:, quantity: 10)
      @import = import
      @person = person
      @quantity = quantity
    end

    def call!
      ActiveRecord::Base.transaction do
        @import.update!(person: @person)

        drug = DrugProduct.find_or_create_by!(display_name: "仮: ロキソニン") do |d|
          d.is_temporary = true
        end

        item = MedicationItem.find_or_create_by!(person: @person, drug_product: drug) do |i|
         i.active = true
        end
        
        base_date = Date.today
        shelf_life_days = drug.shelf_life_days_or_default
        expires_on = base_date + shelf_life_days

        item.medication_lots.create!(
          base_date: base_date,
          shelf_life_days: shelf_life_days,
          expires_on: expires_on,
          quantity_initial: @quantity,
          quantity_remaining: @quantity
        )
      end
    end
  end
end