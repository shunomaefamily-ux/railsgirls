class AddUsageTextToMedicationItems < ActiveRecord::Migration[8.1]
  def change
    add_column :medication_items, :usage_text, :string
  end
end
