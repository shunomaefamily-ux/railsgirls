class DrugProduct < ApplicationRecord
  has_many :medication_items, dependent: :destroy
  has_many :people, through: :medication_items

  validates :default_shelf_life_days,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true


    # 未設定なら 365日を採用（MVP用の割り切り）
  def shelf_life_days_or_default
    default_shelf_life_days.presence || 365
  end

end