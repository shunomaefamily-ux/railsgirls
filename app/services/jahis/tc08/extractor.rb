# app/services/jahis/tc08/extractor.rb
# JAHIS TC08 (JAHISTC08) のCSVテキストを「最低限」読み取る抽出器
#
# 目的（MVP）:
# - バージョンが JAHISTC08 かを軽くチェック
# - 調剤等年月日レコード(5) から base_date を取る
# - 薬品レコード(201) から rp番号/薬品名称/用量/単位/コード類を取る
# - 用法レコード(301) は “行を文字列で保持” まで（列解釈は後で）

require "csv"

module Jahis
  module Tc08
    Result = Struct.new(
      :version,
      :base_date,   # Date or nil
      :drugs,       # Array<Hash>
      :raw_usage_by_rp, # { rp_no(Integer) => Array<String> }  (301をそのまま保持)
      keyword_init: true
    )

    class Extractor
      def initialize(raw_text:)
        @raw_text = raw_text.to_s
      end

      def call
        lines = normalize_lines(@raw_text)
        rows  = parse_csv_lines(lines)

        version = extract_version(rows)
        base_date = extract_base_date(rows)
        drugs = extract_201_drugs(rows)
        raw_usage_by_rp = extract_301_raw(rows)

        Result.new(
          version: version,
          base_date: base_date,
          drugs: drugs,
          raw_usage_by_rp: raw_usage_by_rp
        )
      end

      private

      def normalize_lines(text)
        # QR読み取り結果は改行が \n / \r\n 混在しがちなので統一
        normalized = text.gsub("\r\n", "\n").gsub("\r", "\n")
        # 先頭BOMが混ざる環境もあるので除去
        normalized = normalized.sub("\uFEFF", "")
        normalized.split("\n").map(&:strip).reject(&:blank?)
      end

      def parse_csv_lines(lines)
        # 仕様：ダブルクォートで囲まない、半角カンマが区切り
        # （ただし現実にはクォートが混ざることもあるので CSV に任せる）
        lines.map do |line|
          CSV.parse_line(line, col_sep: ",") || []
        rescue CSV::MalformedCSVError
          # 壊れていても落とさず、最悪「カンマsplit」で救う
          line.split(",")
        end
      end

      def extract_version(rows)
        # バージョンレコードの形式は仕様にあるが、ここでは「JAHISTC08 を含む行」を探すだけにする（MVP）
        row = rows.find { |r| r.any? { |v| v.to_s.include?("JAHISTC08") } }
        row&.find { |v| v.to_s.include?("JAHISTC08") }
      end

      def extract_base_date(rows)
        # 調剤等年月日レコード: 5,YYYYMMDD,作成者...
        row = rows.find { |r| r[0].to_s.strip == "5" }
        return nil unless row

        ymd = row[1].to_s.strip
        parse_yyyymmdd(ymd)
      end

      def extract_201_drugs(rows)
        rows
          .select { |r| r[0].to_s.strip == "201" }
          .map { |r| parse_201_row(r) }
          .compact
      end

      def parse_201_row(r)
        # サンプルから最低限: 201,RP番号,薬品名称,用量,単位,... という並びで出てくる :contentReference[oaicite:4]{index=4}
        rp_no = safe_int(r[1])
        name  = r[2].to_s.strip
        return nil if name.blank?

        dose = safe_decimal(r[3])
        unit = r[4].to_s.strip.presence

        # 後半の詳細項目（カラム位置は仕様表と突合しながら後で改善）
        drug_code_type = safe_int(r[5]) # 例: 2=レセプト電算コード等（仕様に記載） :contentReference[oaicite:5]{index=5}
        drug_code      = r[6].to_s.strip.presence

        record_author  = safe_int(r[7]) # 例: 1/2/8/9 みたいなやつ

        generic_name       = r[8].to_s.strip.presence
        generic_code_type  = safe_int(r[9])
        generic_code       = r[10].to_s.strip.presence

        {
          rp_no: rp_no,
          display_name: name,
          dose: dose,
          unit: unit,
          drug_code_type: drug_code_type,
          drug_code: drug_code,
          record_author: record_author,
          generic_name: generic_name,
          generic_code_type: generic_code_type,
          generic_code: generic_code
        }
      end

      def extract_301_raw(rows)
        # 用法レコード(301)は「RP番号にひもづく」ことは仕様の出力順/関連から分かる :contentReference[oaicite:6]{index=6}
        # ここでは列を解釈せず、行全体を保持する
        h = Hash.new { |hh, k| hh[k] = [] }

        rows.select { |r| r[0].to_s.strip == "301" }.each do |r|
          rp_no = safe_int(r[1])
          next unless rp_no
          h[rp_no] << r.join(",")
        end

        h
      end

      def parse_yyyymmdd(s)
        return nil unless s.match?(/\A\d{8}\z/)
        y = s[0, 4].to_i
        m = s[4, 2].to_i
        d = s[6, 2].to_i
        Date.new(y, m, d)
      rescue ArgumentError
        nil
      end

      def safe_int(v)
        s = v.to_s.strip
        return nil if s.blank?
        Integer(s, 10)
      rescue ArgumentError, TypeError
        nil
      end

      def safe_decimal(v)
        s = v.to_s.strip
        return nil if s.blank?
        BigDecimal(s)
      rescue ArgumentError
        nil
      end
    end
  end
end