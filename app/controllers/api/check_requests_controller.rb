class Api::CheckRequestsController < ApplicationController
  def current
    person = Person
      .includes(medication_items: :drug_product)
      .order(:id)
      .first

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
end