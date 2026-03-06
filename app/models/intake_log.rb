class IntakeLog < ApplicationRecord
  belongs_to :medication_item

  validates :quantity_taken, numericality: { only_integer: true, greater_than: 0 }
  validates :taken_at, presence: true
end