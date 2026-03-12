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

    preview = Imports::PreviewBuilder.new(import: @import).call

    @jahis = preview.jahis
    @suggested_quantities = preview.suggested_quantities
    @usage_texts = preview.usage_texts
    @usage_suggestions = preview.usage_suggestions
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
      quantities: quantities,
      usage_kind_by_index: extract_usage_kind_by_index,
      usage_slots_by_index: extract_usage_slots_by_index
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

  def import_params
    params.permit(:raw_text, :source)
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

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
      raise ArgumentError, "入庫数は1以上で入力してください" if quantities_int.values.all? { |value| value <= 0 }
      return
    end

    raise ArgumentError, "入庫数は1以上で入力してください" if quantity <= 0
  end

  def extract_usage_kind_by_index
    params.permit(usage_kind_by_index: {})
          .fetch(:usage_kind_by_index, {})
          .to_h
  end

  def extract_usage_slots_by_index
    raw = params[:usage_slots_by_index] || {}
    raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
  end

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