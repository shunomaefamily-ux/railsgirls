class MedicationLot < ApplicationRecord
  belongs_to :medication_item

  validates :base_date, presence: true
  validates :expires_on, presence: true
  validates :quantity_initial, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_remaining, numericality: { greater_than_or_equal_to: 0 }

  validate :quantity_remaining_not_exceed_initial

  scope :remaining, -> { where("quantity_remaining > 0") }
  scope :fifo, -> { order(base_date: :asc, id: :asc) }
  scope :expired, -> { where("expires_on < ?", Date.current) }
  scope :expiring_within, ->(days) { where(expires_on: Date.current..(Date.current + days)) }

  private

  def quantity_remaining_not_exceed_initial
    return if quantity_initial.blank? || quantity_remaining.blank?
    return if quantity_remaining <= quantity_initial

    errors.add(:quantity_remaining, "は初期数量以下である必要があります")
  end
end