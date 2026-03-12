class MedicationItem < ApplicationRecord
  EXPIRY_WARNING_DAYS = 30

  belongs_to :person
  belongs_to :drug_product

  has_many :medication_lots, dependent: :destroy
  has_many :intake_logs, dependent: :destroy

  enum :usage_kind, {
    regular: "regular",
    prn: "prn"
  }, prefix: true

  USAGE_SLOTS = %w[morning noon evening].freeze

  validates :usage_kind, inclusion: { in: usage_kinds.keys }, allow_nil: true
  validate :usage_slots_must_be_valid
  validate :usage_kind_and_slots_must_make_sense

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

  def for_slot?(slot)
    return false if usage_kind_prn?
    usage_slots.include?(slot.to_s)
  end

  private

  def usage_slots_must_be_valid
    invalid = Array(usage_slots) - USAGE_SLOTS
    return if invalid.empty?

    errors.add(:usage_slots, "に不正な値があります")
  end

  def usage_kind_and_slots_must_make_sense
    return if usage_kind.blank?

    if usage_kind_regular? && usage_slots.blank?
      errors.add(:usage_slots, "を1つ以上選択してください")
    end

    if usage_kind_prn? && usage_slots.present?
      errors.add(:usage_slots, "頓服の場合は空にしてください")
    end
  end
end