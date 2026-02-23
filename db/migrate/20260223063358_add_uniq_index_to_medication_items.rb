class AddUniqIndexToMedicationItems < ActiveRecord::Migration[7.1]
  def change
    add_index :medication_items, [:person_id, :drug_product_id], unique: true
  end
end