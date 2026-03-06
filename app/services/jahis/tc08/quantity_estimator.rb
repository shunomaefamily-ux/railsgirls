# app/services/jahis/tc08/quantity_estimator.rb
require "csv"

module Jahis
  module Tc08
    class QuantityEstimator
      def self.call(drug:, raw_usage_lines:)
        new(drug: drug, raw_usage_lines: raw_usage_lines).call
      end

      def initialize(drug:, raw_usage_lines:)
        @drug = drug
        @raw_usage_lines = Array(raw_usage_lines)
      end

      def call
        dose = safe_decimal(@drug[:dose])
        return 0 if dose <= 0

        usage = parse_first_301(@raw_usage_lines)
        return 0 if usage.nil?

        dosage_form_code = usage[:dosage_form_code]
        dispense_quantity = usage[:dispense_quantity]
        usage_name = usage[:usage_name].to_s

        case dosage_form_code
        when 1
          times_per_day = extract_times_per_day(usage_name)
          return 0 if times_per_day <= 0 || dispense_quantity <= 0

          (dose * times_per_day * dispense_quantity).ceil
        when 3
          return 0 if dispense_quantity <= 0

          (dose * dispense_quantity).ceil
        else
          0
        end
      rescue StandardError
        0
      end

      private

      def parse_first_301(lines)
        line = lines.first.to_s
        return nil if line.blank?

        cols = CSV.parse_line(line, col_sep: ",")
        return nil if cols.blank?

        {
          rp_no: safe_int(cols[1]),
          usage_name: cols[2].to_s.strip,
          dispense_quantity: safe_int(cols[3]) || 0,
          dispense_unit: cols[4].to_s.strip,
          dosage_form_code: safe_int(cols[5])
        }
      rescue CSV::MalformedCSVError
        nil
      end

      def extract_times_per_day(text)
        normalized = normalize_text(text)

        if normalized =~ /1日(\d+)回/
          return Regexp.last_match(1).to_i
        end

        if normalized =~ /分(\d+)/
          return Regexp.last_match(1).to_i
        end

        0
      end

      def normalize_text(text)
        text.to_s.tr("０-９", "0-9").gsub(/\s+/, "")
      end

      def safe_int(value)
        str = value.to_s.strip
        return nil if str.blank?

        Integer(str, 10)
      rescue ArgumentError, TypeError
        nil
      end

      def safe_decimal(value)
        return 0.to_d if value.nil?

        BigDecimal(value.to_s)
      rescue ArgumentError, TypeError
        0.to_d
      end
    end
  end
end