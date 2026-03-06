class MedicationItem < ApplicationRecord
  EXPIRY_WARNING_DAYS = 30

  belongs_to :person
  belongs_to :drug_product

  has_many :medication_lots, dependent: :destroy
  has_many :intake_logs, dependent: :destroy

  def remaining_quantity
    medication_lots.sum(:quantity_remaining)
  end

  def consume!(amount, taken_at: Time.current)
    Stock::Consume.new(
      medication_item: self,
      quantity: amount,
      taken_at: taken_at
    ).call
  end

  def last_taken_at
    intake_logs.order(taken_at: :desc).limit(1).pick(:taken_at)
  end

  def nearest_expires_on
    medication_lots.remaining.minimum(:expires_on)
  end

  def expired?
    expires_on = nearest_expires_on
    expires_on.present? && expires_on < Date.current
  end

  def expiring_soon?(remaining_days = EXPIRY_WARNING_DAYS)
    expires_on = nearest_expires_on
    expires_on.present? &&
      expires_on >= Date.current &&
      expires_on <= Date.current + remaining_days
  end

  def expired_lots
    medication_lots.remaining.expired.fifo
  end
end