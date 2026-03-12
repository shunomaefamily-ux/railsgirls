class AddUsageToMedicationItems < ActiveRecord::Migration[8.1]
  def change
    add_column :medication_items, :usage_kind, :string
    add_column :medication_items, :usage_slots, :json, default: [], null: false

    add_index :medication_items, :usage_kind
  end
end