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

    @jahis_tc08 =
      if @import.raw_text.to_s.start_with?("JAHISTC08")
        Jahis::Tc08::Extractor.new(raw_text: @import.raw_text).call
      end
  end

  def register
    import = Import.find(params[:id])
    choice = params[:person_choice].to_s

    if choice.blank?
      redirect_to import_path(import), alert: "登録者を選択してください"
      return
    end

    person =
      if choice == "new"
        attrs = params.fetch(:person_attributes, {}).permit(:name)
        name = attrs[:name].to_s.strip
        if name.blank?
          redirect_to import_path(import), alert: "新規作成する場合は名前が必要です"
          return
        end
        Person.create!(name: name)
      else
        Person.find(choice)
      end

   # 単一quantity（旧仕様）も残しつつ、複数薬なら quantities を優先
  quantity = params[:quantity].to_i
  quantities = params.permit(quantities: {}).fetch(:quantities, {}).to_h # {"0"=>"10","1"=>"5",...} になる想定

  # quantities が来ている場合は、1つでも1以上があるかチェック
  if quantities.present?
    quantities_int = quantities.transform_values { |v| v.to_i }
    if quantities_int.values.all? { |v| v <= 0 }
      redirect_to import_path(import), alert: "入庫数は1以上で入力してください"
      return
    end
  else
    if quantity <= 0
      redirect_to import_path(import), alert: "入庫数は1以上で入力してください"
      return
    end
  end

  begin
    Imports::RegisterAndSeedStock.new(
      import: import,
      person: person,
      quantity: quantity,                 # 旧仕様用（予備）
      quantities: quantities              # 新仕様用（薬ごと）
    ).call!

    msg_qty =
      if quantities.present?
        "薬ごと入庫"
      else
        "入庫#{quantity}"
      end

    redirect_to root_path, notice: "在庫に登録しました（#{person.name} / #{msg_qty}）"
      rescue ArgumentError => e
        redirect_to import_path(import), alert: e.message
      rescue ActiveRecord::RecordInvalid => e
        redirect_to import_path(import), alert: e.message
      end

  end

  private

  def import_params
    params.permit(:raw_text, :source)
  end
end