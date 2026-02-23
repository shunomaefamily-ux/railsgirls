class CreateIntakeLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :intake_logs do |t|
      t.references :medication_item, null: false, foreign_key: true
      t.integer :quantity_taken
      t.datetime :taken_at

      t.timestamps
    end
  end
end
