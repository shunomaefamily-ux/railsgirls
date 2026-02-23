# frozen_string_literal: true

module Stock
  class Consume
    class OutOfStock < StandardError; end

    def initialize(medication_item:, quantity:, taken_at: Time.current)
      @item = medication_item
      @quantity = quantity
      @taken_at = taken_at
    end

    def call
      ApplicationRecord.transaction do
        IntakeLog.create!(
          medication_item: @item,
          quantity_taken: @quantity,
          taken_at: @taken_at
        )

        consume_from_lots!(@quantity)
      end

      true
    end

    private

    def consume_from_lots!(qty)
      remaining_to_consume = qty

      lots = @item.medication_lots
                  .where("quantity_remaining > 0")
                  .order(base_date: :asc, id: :asc)
                  .lock

      lots.each do |lot|
        break if remaining_to_consume <= 0

        take = [lot.quantity_remaining, remaining_to_consume].min
        lot.update!(quantity_remaining: lot.quantity_remaining - take)
        remaining_to_consume -= take
      end

      raise OutOfStock, "在庫が足りません" if remaining_to_consume > 0
    end
  end
end