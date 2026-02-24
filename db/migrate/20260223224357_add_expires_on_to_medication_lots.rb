class AddExpiresOnToMedicationLots < ActiveRecord::Migration[8.1]
  def change
    add_column :medication_lots, :expires_on, :date
    add_index  :medication_lots, :expires_on #検索用タグ（ロットと期限を記憶）
  end
end
