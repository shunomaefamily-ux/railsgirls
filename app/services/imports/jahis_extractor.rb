module Imports
  class JahisExtractor
    def initialize(raw_text:)
      @raw_text = raw_text
    end

    def call!
      raw = normalize(@raw_text)

      extracted =
        if raw.start_with?("JAHISTC08")
          Jahis::Tc08::Extractor.new(raw_text: raw).call
        elsif raw.start_with?("JAHISTC06")
          Jahis::Tc06::Extractor.new(raw_text: raw).call
        end

      raise ArgumentError, "JAHISTC06/08形式ではありません（手入力で登録してください）" unless extracted

      extracted
    end

    private

    def normalize(text)
      text.to_s
          .sub("\uFEFF", "")
          .gsub("\r\n", "\n")
          .gsub("\r", "\n")
          .strip
    end
  end
end