module Imports
  class PreviewBuilder
    attr_reader :jahis, :suggested_quantities, :usage_texts, :usage_suggestions

    def initialize(import:)
      @import = import
    end

    def call
      @jahis = extract_jahis(@import)
      @suggested_quantities = build_suggested_quantities(@jahis)
      @usage_texts = build_usage_texts(@jahis)
      @usage_suggestions = build_usage_suggestions(@jahis)

      self
    end

    private

    def extract_jahis(import)
      raw = normalize_jahis_text(import.raw_text)

      if first_line(raw).start_with?("JAHISTC08")
        Jahis::Tc08::Extractor.new(raw_text: raw).call
      elsif first_line(raw).start_with?("JAHISTC06")
        Jahis::Tc06::Extractor.new(raw_text: raw).call
      end
    end

    def normalize_jahis_text(text)
      text.to_s
          .sub("\uFEFF", "")
          .gsub("\r\n", "\n")
          .gsub("\r", "\n")
          .strip
    end

    def first_line(text)
      text.to_s.lines.first.to_s.strip
    end

    def build_suggested_quantities(jahis)
      return {} unless jahis

      jahis.drugs.each_with_index.each_with_object({}) do |(drug, index), result|
        raw_usage_lines = jahis.raw_usage_by_rp[drug[:rp_no]]

        result[index] =
          Jahis::QuantityEstimator.call(
            drug: drug,
            raw_usage_lines: raw_usage_lines
          )
      end
    end

    def build_usage_texts(jahis)
      return {} unless jahis

      jahis.drugs.each_with_index.each_with_object({}) do |(drug, index), result|
        raw_usage_lines = jahis.raw_usage_by_rp[drug[:rp_no]]
        result[index] = extract_usage_text(raw_usage_lines)
      end
    end

    def extract_usage_text(raw_usage_lines)
      line = Array(raw_usage_lines).first.to_s
      return nil if line.blank?

      cols = CSV.parse_line(line, col_sep: ",")
      return nil if cols.blank?

      cols[2].to_s.strip.presence
    rescue CSV::MalformedCSVError
      nil
    end

    def build_usage_suggestions(jahis)
      return {} unless jahis

      Imports::UsageSuggestionBuilder.new(
        drugs: jahis.drugs,
        usage_texts: @usage_texts
      ).call
    end
  end
end