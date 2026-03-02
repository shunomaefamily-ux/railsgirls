# app/services/imports/extractors/basic_extractor.rb
module Imports
  module Extractors
    Result = Struct.new(
      :display_name,
      :quantity,
      :base_date,
      :expires_on,
      keyword_init: true
    )

    class BasicExtractor
      # MVP: raw_text をそのまま薬名っぽく扱う（後でJAHIS抽出に差し替える）
      def self.call(raw_text)
        text = raw_text.to_s.strip

        Result.new(
          display_name: text.first(40).presence || "不明な薬",
          quantity: nil,        # 基本は取れない前提（入力で補う）
          base_date: nil,        # 取れない前提（todayで補う）
          expires_on: nil        # 取れない前提（shelf_life_daysで補う）
        )
      end
    end
  end
end