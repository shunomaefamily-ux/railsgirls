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

    quantity = lot_params[:quantity].to_i
    base_date = parse_date(lot_params[:base_date])
    expires_on = parse_date(lot_params[:expires_on])

    @lot = @item.medication_lots.new(
      base_date: base_date,
      expires_on: expires_on,
      shelf_life_days: calculate_shelf_life_days(base_date, expires_on),
      quantity_initial: quantity,
      quantity_remaining: quantity
    )

    if @lot.save
      redirect_to root_path, notice: "入庫しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def discard
    @item = MedicationItem.find(params[:medication_item_id])
    @lot  = @item.medication_lots.find(params[:id])

    @lot.update!(quantity_remaining: 0)

    redirect_to root_path, notice: "期限切れロットを捨てました"
  end

  private

  def lot_params
    params.require(:medication_lot).permit(:base_date, :expires_on, :quantity)
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def calculate_shelf_life_days(base_date, expires_on)
    return nil if base_date.nil? || expires_on.nil?

    (expires_on - base_date).to_i
  end
end