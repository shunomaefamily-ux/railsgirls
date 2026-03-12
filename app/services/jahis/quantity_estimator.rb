# app/services/jahis/quantity_estimator.rb
require "csv"
require "bigdecimal"

module Jahis
  class QuantityEstimator
    def self.call(drug:, raw_usage_lines:)
      new(drug: drug, raw_usage_lines: raw_usage_lines).call
    end

    def initialize(drug:, raw_usage_lines:)
      @drug = drug
      @raw_usage_lines = Array(raw_usage_lines)
    end

    def call
      usage = parse_first_301(@raw_usage_lines)
      return 0 if usage.nil?

      dosage_form_code = usage[:dosage_form_code]
      dispense_quantity = usage[:dispense_quantity]

      case dosage_form_code
      when 1, nil
        dose = safe_decimal(@drug[:dose])
        return 0 if dose <= 0 || dispense_quantity <= 0

        (dose * dispense_quantity).ceil
      when 3
        dose = safe_decimal(@drug[:dose])
        return 0 if dose <= 0 || dispense_quantity <= 0

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
        dosage_form_code: safe_int(cols[6]) || safe_int(cols[5])
      }
    rescue CSV::MalformedCSVError
      nil
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