class CreateDrugProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :drug_products do |t|
      t.string :display_name
      t.boolean :is_temporary

      t.timestamps
    end
  end
end
