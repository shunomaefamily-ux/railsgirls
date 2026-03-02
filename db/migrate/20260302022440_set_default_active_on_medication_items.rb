class SetDefaultActiveOnMedicationItems < ActiveRecord::Migration[8.1]
  def change
    change_column_default :medication_items, :active, from: nil, to: true
  end
end