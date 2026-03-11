module CheckRequests
  class ConfirmCurrent
    def initialize(person:, taken_at: Time.current)
      @person = person
      @taken_at = taken_at
    end

    def call!
      items = @person.medication_items.select { |item| item.remaining_quantity > 0 }

      raise ArgumentError, "確認対象の薬がありません" if items.empty?

      ActiveRecord::Base.transaction do
        items.each do |item|
          item.consume!(1, taken_at: @taken_at)
        end
      end

      true
    end
  end
end