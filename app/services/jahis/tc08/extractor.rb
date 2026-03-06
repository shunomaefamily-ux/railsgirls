# app/services/jahis/tc08/extractor.rb
# JAHIS TC08 (JAHISTC08) のCSVテキストを最低限読み取る抽出器
#
# MVPで扱う内容:
# - バージョンが JAHISTC08 かを確認
# - 調剤等年月日レコード(5) から base_date を取得
# - 薬品レコード(201) から最低限の薬情報を取得
# - 用法レコード(301) は列解釈せず、行文字列のまま保持

require "csv"

module Jahis
  module Tc08
    Result = Struct.new(
      :version,
      :base_date,       # Date or nil
      :drugs,           # Array<Hash>
      :raw_usage_by_rp, # { rp_no(Integer) => Array<String> }
      keyword_init: true
    )

    class Extractor
      def initialize(raw_text:)
        @raw_text = raw_text.to_s
      end

      def call
        lines = normalize_lines(@raw_text)
        rows = parse_csv_lines(lines)

        Result.new(
          version: extract_version(rows),
          base_date: extract_base_date(rows),
          drugs: extract_201_drugs(rows),
          raw_usage_by_rp: extract_301_raw(rows)
        )
      end

      private

      def normalize_lines(text)
        normalized = text.gsub("\r\n", "\n").gsub("\r", "\n")
        normalized = normalized.sub("\uFEFF", "")

        normalized
          .split("\n")
          .map(&:strip)
          .reject(&:blank?)
      end

      def parse_csv_lines(lines)
        lines.map do |line|
          CSV.parse_line(line, col_sep: ",") || []
        rescue CSV::MalformedCSVError
          line.split(",")
        end
      end

      def extract_version(rows)
        row = rows.find { |r| r.any? { |v| v.to_s.include?("JAHISTC08") } }
        row&.find { |v| v.to_s.include?("JAHISTC08") }
      end

      def extract_base_date(rows)
        row = rows.find { |r| r[0].to_s.strip == "5" }
        return nil unless row

        parse_yyyymmdd(row[1].to_s.strip)
      end

      def extract_201_drugs(rows)
        rows
          .select { |r| r[0].to_s.strip == "201" }
          .map { |row| parse_201_row(row) }
          .compact
      end

      def parse_201_row(row)
        rp_no = safe_int(row[1])
        name = row[2].to_s.strip
        return nil if name.blank?

        {
          rp_no: rp_no,
          display_name: name,
          dose: safe_decimal(row[3]),
          unit: row[4].to_s.strip.presence,
          drug_code_type: safe_int(row[5]),
          drug_code: row[6].to_s.strip.presence,
          record_author: safe_int(row[7]),
          generic_name: row[8].to_s.strip.presence,
          generic_code_type: safe_int(row[9]),
          generic_code: row[10].to_s.strip.presence
        }
      end

      def extract_301_raw(rows)
        usage_by_rp = Hash.new { |hash, key| hash[key] = [] }

        rows.select { |r| r[0].to_s.strip == "301" }.each do |row|
          rp_no = safe_int(row[1])
          next unless rp_no

          usage_by_rp[rp_no] << row.join(",")
        end

        usage_by_rp
      end

      def parse_yyyymmdd(value)
        return nil unless value.match?(/\A\d{8}\z/)

        y = value[0, 4].to_i
        m = value[4, 2].to_i
        d = value[6, 2].to_i

        Date.new(y, m, d)
      rescue ArgumentError
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
        str = value.to_s.strip
        return nil if str.blank?

        BigDecimal(str)
      rescue ArgumentError
        nil
      end
    end
  end
end