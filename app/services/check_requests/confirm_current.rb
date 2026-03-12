module CheckRequests
  class ConfirmCurrent
    def initialize(person:, taken_at: Time.current, slot: nil)
      @person = person
      @taken_at = taken_at
      @slot = slot
    end

    def call!
      items = target_items

      raise ArgumentError, "確認対象の薬がありません" if items.empty?

      ActiveRecord::Base.transaction do
        items.each do |item|
          item.consume!(1, taken_at: @taken_at)
        end
      end

      true
    end

    private

    def target_items
      @person.medication_items.select do |item|
        next false if item.remaining_quantity <= 0

        if @slot.present?
          regular_item_for_slot?(item, @slot)
        else
          true
        end
      end
    end

    def regular_item_for_slot?(item, slot)
      item.usage_kind == "regular" &&
        Array(item.usage_slots).include?(slot.to_s)
    end
  end
end