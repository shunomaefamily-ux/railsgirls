class Api::CheckRequestsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def current
    person = Person
      .includes(medication_items: :drug_product)
      .find_by(id: params[:person_id])

    return render json: { check_request: nil } if person.nil?

    available_items = person.medication_items.select do |item|
      item.remaining_quantity > 0
    end

    return render json: { check_request: nil } if available_items.empty?

    render json: {
      check_request: {
        id: person.id,
        title: "服薬確認",
        person_name: person.name,
        scheduled_at: "09:00",
        items: available_items.map do |item|
          {
            name: item.drug_product.display_name,
            dose_amount: "1",
            dose_unit: "錠"
          }
        end
      }
    }
  end

  def confirm
    person = Person.find_by(id: params[:id])
    return render json: { error: "対象者が見つかりません" }, status: :not_found if person.nil?

    CheckRequests::ConfirmCurrent.new(person: person).call!

    render json: { ok: true }
  rescue Stock::Consume::OutOfStock, ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end