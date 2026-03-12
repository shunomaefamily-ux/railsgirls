require "csv"

class ImportsController < ApplicationController
  def scan
  end

  def create
    import = Import.new(import_params)

    if import.save
      render json: { id: import.id }, status: :created
    else
      render json: { errors: import.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    @import = Import.find(params[:id])
    @people = Person.order(:id)

    @jahis = extract_jahis(@import)

    @suggested_quantities = build_suggested_quantities(@jahis)
    @usage_texts = build_usage_texts(@jahis)
  end

  def register
    import = Import.find(params[:id])
    person = resolve_person!

    quantity, quantities = extract_quantities
    validate_quantities!(quantity, quantities)

    Imports::RegisterAndSeedStock.new(
      import: import,
      person: person,
      quantity: quantity,
      quantities: quantities
    ).call!

    redirect_to root_path,
                notice: build_register_notice(person, quantity, quantities)

  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to import_path(import), alert: e.message
  end

  def manual_new
    @person = Person.find(params[:person_id])
    @drug_products = DrugProduct.order(:display_name)

    @base_date = Date.current
    @expires_on = Date.current + 1.year
    @quantity = 0
  end

  def manual_create
    @person = Person.find(params[:person_id])

    Stock::Register.call(
      person: @person,
      drug_name: params[:drug_name],
      base_date: parse_date(params[:base_date]),
      expires_on: parse_date(params[:expires_on]),
      quantity: params[:quantity]
    )

    redirect_to root_path, notice: "手動で入庫しました"

  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to new_person_manual_import_path(@person), alert: e.message
  end

  private

  # ------------------------------------------------
  # Import
  # ------------------------------------------------

  def import_params
    params.permit(:raw_text, :source)
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  # ------------------------------------------------
  # JAHIS Extract
  # ------------------------------------------------

  def extract_jahis(import)
    raw = normalize_jahis_text(import.raw_text)

    if jahis_tc08?(raw)
      Jahis::Tc08::Extractor.new(raw_text: raw).call
    elsif jahis_tc06?(raw)
      Jahis::Tc06::Extractor.new(raw_text: raw).call
    else
      nil
    end
  end

  def normalize_jahis_text(text)
    text.to_s
        .sub("\uFEFF", "")
        .gsub("\r\n", "\n")
        .gsub("\r", "\n")
        .strip
  end

  def jahis_tc08?(text)
    first_line(text).start_with?("JAHISTC08")
  end

  def jahis_tc06?(text)
    first_line(text).start_with?("JAHISTC06")
  end

  def first_line(text)
    text.to_s.lines.first.to_s.strip
  end

  # ------------------------------------------------
  # Quantity estimation
  # ------------------------------------------------

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

  # ------------------------------------------------
  # Usage text extraction
  # ------------------------------------------------

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

  # ------------------------------------------------
  # Person
  # ------------------------------------------------

  def resolve_person!
    choice = params[:person_choice].to_s

    raise ArgumentError, "登録者を選択してください" if choice.blank?

    if choice == "new"
      attrs = params.fetch(:person_attributes, {}).permit(:name)

      name = attrs[:name].to_s.strip
      raise ArgumentError, "新規作成する場合は名前が必要です" if name.blank?

      Person.create!(name: name)

    else
      Person.find(choice)
    end
  end

  # ------------------------------------------------
  # Quantity params
  # ------------------------------------------------

  def extract_quantities
    quantity = params[:quantity].to_i

    quantities =
      params.permit(quantities: {})
            .fetch(:quantities, {})
            .to_h

    [quantity, quantities]
  end

  def validate_quantities!(quantity, quantities)
    if quantities.present?
      quantities_int = quantities.transform_values(&:to_i)

      return unless quantities_int.values.all? { |value| value <= 0 }

      raise ArgumentError, "入庫数は1以上で入力してください"
    end

    raise ArgumentError, "入庫数は1以上で入力してください" if quantity <= 0
  end

  # ------------------------------------------------
  # Notice
  # ------------------------------------------------

  def build_register_notice(person, quantity, quantities)
    msg_qty =
      if quantities.present?
        "薬ごと入庫"
      else
        "入庫#{quantity}"
      end

    "在庫に登録しました（#{person.name} / #{msg_qty}）"
  end
end