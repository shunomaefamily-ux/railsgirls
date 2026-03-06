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
    
    @suggested_quantities = {}

    if @jahis_tc08
      @jahis_tc08.drugs.each_with_index do |drug, i|
        raw_usage_lines = @jahis_tc08.raw_usage_by_rp[drug[:rp_no]]

        @suggested_quantities[i] = Jahis::Tc08::QuantityEstimator.call(
          drug: drug,
          raw_usage_lines: raw_usage_lines
        )
      end
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


  def manual_new
    @person = Person.find(params[:person_id])
    @drug_products = DrugProduct.order(:display_name)

    @base_date = Date.current
    @expires_on = Date.current + 1.year
    @quantity = 0
  end


  def manual_create
    @person = Person.find(params[:person_id])

    drug_name = params[:drug_name].to_s.strip
    quantity  = params[:quantity].to_i

    base_date =
      begin
        Date.parse(params[:base_date].to_s)
      rescue ArgumentError
        nil
      end

    expires_on =
      begin
        Date.parse(params[:expires_on].to_s)
      rescue ArgumentError
        nil
      end

    if drug_name.blank?
      redirect_to new_person_manual_import_path(@person), alert: "薬名を入力してください"
      return
    end

    if quantity <= 0
      redirect_to new_person_manual_import_path(@person), alert: "数量は1以上で入力してください"
      return
    end

    if base_date.nil?
      redirect_to new_person_manual_import_path(@person), alert: "入庫日を入力してください"
      return
    end

    if expires_on.nil?
      redirect_to new_person_manual_import_path(@person), alert: "期限を入力してください"
      return
    end

    drug = DrugProduct.find_or_create_by!(display_name: drug_name) do |dp|
      dp.is_temporary = true if dp.respond_to?(:is_temporary=)
    end

    item = MedicationItem.find_or_create_by!(person: @person, drug_product: drug) do |mi|
      mi.active = true
    end

    shelf_life_days = (expires_on - base_date).to_i

    item.medication_lots.create!(
      base_date: base_date,
      expires_on: expires_on,
      shelf_life_days: shelf_life_days,
      quantity_initial: quantity,
      quantity_remaining: quantity
    )

    redirect_to root_path, notice: "手動で入庫しました"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_person_manual_import_path(@person), alert: e.message
  end



  private

  def import_params
    params.permit(:raw_text, :source)
  end
  
end