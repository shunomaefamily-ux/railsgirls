class MedicationLot < ApplicationRecord
  belongs_to :medication_item

  scope :remaining, -> { where("quantity_remaining > 0") }
  scope :fifo, -> { order(base_date: :asc, id: :asc) }
end
