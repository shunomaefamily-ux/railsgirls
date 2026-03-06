class MedicationItemsController < ApplicationController
  def consume_one
    item = MedicationItem.find(params[:id])
    item.consume!(1)

    redirect_to root_path, notice: "1つ消費しました"
  rescue Stock::Consume::OutOfStock => e
    redirect_to root_path, alert: e.message
  rescue ArgumentError => e
    redirect_to root_path, alert: e.message
  end
end