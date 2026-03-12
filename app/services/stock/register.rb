module Stock
  class Register
    def self.call(person:, base_date:, expires_on:, quantity:, drug_name: nil, drug_product: nil, usage_text: nil)
      new(
        person: person,
        drug_name: drug_name,
        drug_product: drug_product,
        base_date: base_date,
        expires_on: expires_on,
        quantity: quantity,
        usage_text: usage_text
      ).call
    end

    def initialize(person:, base_date:, expires_on:, quantity:, drug_name: nil, drug_product: nil, usage_text: nil)
      @person = person
      @drug_name = drug_name.to_s.strip
      @drug_product = drug_product
      @base_date = base_date
      @expires_on = expires_on
      @quantity = quantity.to_i
      @usage_text = usage_text.to_s.strip.presence
    end

    def call
      ActiveRecord::Base.transaction do
        validate_inputs!

        drug = resolve_drug!
        item = find_or_create_item!(drug)
        update_item_usage_text!(item)

        lot = item.medication_lots.create!(
          base_date: @base_date,
          expires_on: @expires_on,
          shelf_life_days: shelf_life_days,
          quantity_initial: @quantity,
          quantity_remaining: @quantity
        )

        { drug:, item:, lot: }
      end
    end

    private

    def validate_inputs!
      raise ArgumentError, "薬を指定してください" if @drug_product.nil? && @drug_name.blank?
      raise ArgumentError, "数量は1以上で入力してください" if @quantity <= 0
      raise ArgumentError, "入庫日を入力してください" if @base_date.nil?
      raise ArgumentError, "期限を入力してください" if @expires_on.nil?
      raise ArgumentError, "期限は入庫日以降で入力してください" if @expires_on < @base_date
    end

    def resolve_drug!
      @drug_product || find_or_create_drug!
    end

    def find_or_create_drug!
      DrugProduct.find_or_create_by!(display_name: @drug_name) do |dp|
        dp.is_temporary = true if dp.respond_to?(:is_temporary=)
      end
    end

    def find_or_create_item!(drug)
      MedicationItem.find_or_create_by!(person: @person, drug_product: drug) do |mi|
        mi.active = true
        mi.usage_text = @usage_text if mi.respond_to?(:usage_text=) && @usage_text.present?
      end
    end

    def update_item_usage_text!(item)
      return unless item.respond_to?(:usage_text=)
      return if @usage_text.blank?
      return if item.usage_text == @usage_text

      item.update!(usage_text: @usage_text)
    end

    def shelf_life_days
      (@expires_on - @base_date).to_i
    end
  end
end