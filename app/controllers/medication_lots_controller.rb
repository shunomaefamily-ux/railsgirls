class MedicationLotsController < ApplicationController
  def new
    @item = MedicationItem.find(params[:medication_item_id])

    base_date = Date.current
    days = @item.drug_product.shelf_life_days_or_default

    @lot = @item.medication_lots.new(
      base_date: base_date,
      expires_on: base_date + days
    )
  end

  def create
    @item = MedicationItem.find(params[:medication_item_id])
    @lot = @item.medication_lots.new(lot_params)

    # MVP方針：入庫量＝残量として登録（まずはシンプル）
    # フォームで quantity_remaining を入力する形にする
    if @lot.save
      redirect_to root_path, notice: "入庫しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def discard
   @item = MedicationItem.find(params[:medication_item_id])
   @lot  = @item.medication_lots.find(params[:id]) # そのitemのlotだけ触れるようにする

   @lot.update!(quantity_remaining: 0)

   redirect_to root_path, notice: "期限切れロットを捨てました"
  end

  private

  def lot_params
    params.require(:medication_lot).permit(:base_date, :expires_on, :quantity_remaining)
  end


  
end