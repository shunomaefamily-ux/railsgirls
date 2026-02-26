class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports do |t|
      t.references :person, null: false, foreign_key: true
      t.text :raw_text
      t.string :source

      t.timestamps
    end
  end
end
