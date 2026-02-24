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
    end

    true
  end

end
