class AllowNullPersonIdOnImports < ActiveRecord::Migration[8.1]
  def change
    change_column_null :imports, :person_id, true
  end
end