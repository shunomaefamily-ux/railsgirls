class MedicationItem < ApplicationRecord
  belongs_to :person
  belongs_to :drug_product

  has_many :medication_lots, dependent: :destroy
  has_many :intake_logs, dependent: :destroy

  def remaining_quantity
    medication_lots.sum(:quantity_remaining)
  end

  def consume!(amount)
    amount = amount.to_i
    return false if amount <= 0
    return false if remaining_quantity < amount

    ApplicationRecord.transaction do
      remaining = amount

      medication_lots.remaining.fifo.lock.each do |lot|
        break if remaining == 0

        take = [lot.quantity_remaining, remaining].min
        lot.update!(quantity_remaining: lot.quantity_remaining - take)
        remaining -= take
      end

      intake_logs.create!(
        quantity_taken: amount,
        taken_at: Time.current
     )


      

    end

    true
  end

  def last_taken_at
    intake_logs.order(taken_at: :desc).limit(1).pick(:taken_at)
  end

 def expired?
   d = nearest_expires_on
   d.present? && d < Date.current
 end

 EXPIRY_WARNING_DAYS = 30

def nearest_expires_on
  medication_lots.remaining.minimum(:expires_on)
end

 def expiring_soon?(remaining_days = EXPIRY_WARNING_DAYS)
   d = nearest_expires_on
   d.present? && d >= Date.current && d <= Date.current + remaining_days
 end

end
