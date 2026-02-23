class CreateMedicationLots < ActiveRecord::Migration[8.1]
  def change
    create_table :medication_lots do |t|
      t.references :medication_item, null: false, foreign_key: true
      t.integer :quantity_initial
      t.integer :quantity_remaining
      t.date :base_date
      t.integer :shelf_life_days

      t.timestamps
    end
  end
end
