class AddIndexesToLotsAndLogs < ActiveRecord::Migration[7.1]
  def change
    add_index :medication_lots, [:medication_item_id, :base_date]
    add_index :intake_logs, [:medication_item_id, :taken_at]
  end
end