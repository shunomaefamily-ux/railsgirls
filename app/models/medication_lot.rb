class MedicationLot < ApplicationRecord
  belongs_to :medication_item

  validates :quantity_remaining, numericality: { greater_than_or_equal_to: 0 }
  validates :base_date, presence: true
  validates :expires_on, presence: true



  scope :remaining, -> { where("quantity_remaining > 0") }
  scope :fifo, -> { order(base_date: :asc, id: :asc) }

  scope :expired, -> { where("expires_on < ?", Date.current) }
  scope :expiring_within, ->(days) { where(expires_on: Date.current..(Date.current + days)) }

end
