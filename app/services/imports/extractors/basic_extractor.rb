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
      # MVP:
      # raw_text をそのまま薬名候補として扱う簡易抽出器
      # 将来は JAHIS 抽出などに差し替える想定
      def self.call(raw_text)
        text = raw_text.to_s.strip

        Result.new(
          display_name: text.first(40).presence || "不明な薬",
          quantity: nil,
          base_date: nil,
          expires_on: nil
        )
      end
    end
  end
end