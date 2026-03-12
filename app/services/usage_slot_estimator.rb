class UsageSlotEstimator
  Result = Struct.new(:usage_kind, :usage_slots, keyword_init: true)

  def self.call(usage_text)
    text = usage_text.to_s

    return Result.new(usage_kind: "prn", usage_slots: []) if prn_text?(text)

    slots = []

    if text.include?("毎食")
      slots = %w[morning noon evening]
    else
      slots << "morning" if text.include?("朝")
      slots << "noon" if text.include?("昼")
      slots << "evening" if text.include?("夕") || text.include?("夜")
    end

    Result.new(
      usage_kind: "regular",
      usage_slots: slots.uniq
    )
  end

  def self.prn_text?(text)
    text.match?(/頓服|必要時|発作時/)
  end
end