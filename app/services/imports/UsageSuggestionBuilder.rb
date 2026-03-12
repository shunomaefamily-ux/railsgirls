module Imports
  class UsageSuggestionBuilder
    def initialize(drugs:, usage_texts:)
      @drugs = drugs
      @usage_texts = usage_texts
    end

    def call
      @drugs.each_with_index.each_with_object({}) do |(drug, index), result|
        usage_text = @usage_texts[index]
        previous_item = find_previous_medication_item(drug[:display_name])

        result[index] =
          if previous_item.present?
            {
              usage_kind: previous_item.usage_kind,
              usage_slots: Array(previous_item.usage_slots)
            }
          else
            estimated = UsageSlotEstimator.call(usage_text)
            {
              usage_kind: estimated.usage_kind,
              usage_slots: estimated.usage_slots
            }
          end
      end
    end

    private

    def find_previous_medication_item(display_name)
      MedicationItem
        .joins(:drug_product)
        .where(drug_products: { display_name: display_name })
        .where.not(usage_kind: nil)
        .order(updated_at: :desc)
        .first
    end
  end
end