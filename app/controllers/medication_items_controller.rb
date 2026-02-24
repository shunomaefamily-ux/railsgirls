class MedicationItemsController < ApplicationController
  def consume_one
    item = MedicationItem.find(params[:id])

    if item.consume!(1)
      redirect_to root_path, notice: "1つ消費しました"
    else
      redirect_to root_path, alert: "在庫がありません"
    end
  end
end