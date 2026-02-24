class AddDefaultShelfLifeDaysToDrugProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :drug_products, :default_shelf_life_days, :integer
  end
end
