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

    # ★ここだけ差し替え：import.update! をやめてサービス呼び出し
    Imports::RegisterAndSeedStock.new(import: import, person: person, quantity: 10).call!

    redirect_to root_path, notice: "登録者を確定しました（#{person.name}）在庫を追加しました"
  end

  private

  def import_params
    params.permit(:raw_text, :source)
  end
end