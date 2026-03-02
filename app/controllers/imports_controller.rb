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
    @jahis_tc08 = @import.raw_text.to_s.start_with?("JAHISTC08")
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

    quantity = params[:quantity].to_i
    if quantity <= 0
      redirect_to import_path(import), alert: "入庫数は1以上で入力してください"
      return
    end

    begin
      Imports::RegisterAndSeedStock.new(import: import, person: person, quantity: quantity).call!
      redirect_to root_path, notice: "在庫に登録しました（#{person.name} / 入庫#{quantity}）"
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