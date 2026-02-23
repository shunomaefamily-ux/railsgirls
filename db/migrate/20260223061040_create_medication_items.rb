class CreateMedicationItems < ActiveRecord::Migration[8.1]
  def change
    create_table :medication_items do |t|
      t.references :person, null: false, foreign_key: true
      t.references :drug_product, null: false, foreign_key: true
      t.boolean :active

      t.timestamps
    end
  end
end
