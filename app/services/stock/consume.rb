# app/services/stock/consume.rb
# frozen_string_literal: true

module Stock
  class Consume
    class OutOfStock < StandardError; end

    def initialize(medication_item:, quantity:, taken_at: Time.current)
      @item = medication_item
      @quantity = quantity.to_i
      @taken_at = taken_at
    end

    def call
      raise ArgumentError, "消費数量は1以上で指定してください" if @quantity <= 0

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

    def consume_from_lots!(requested_quantity)
      remaining_to_consume = requested_quantity

      lots = @item.medication_lots
                  .where("quantity_remaining > 0")
                  .order(base_date: :asc, id: :asc)
                  .lock

      lots.each do |lot|
        break if remaining_to_consume <= 0

        consumed_quantity = [lot.quantity_remaining, remaining_to_consume].min

        lot.update!(
          quantity_remaining: lot.quantity_remaining - consumed_quantity
        )

        remaining_to_consume -= consumed_quantity
      end

      raise OutOfStock, "在庫が足りません" if remaining_to_consume > 0
    end
  end
end