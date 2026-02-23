class HomeController < ApplicationController
  def index
    @people = Person
      .includes(medication_items: [:drug_product, :medication_lots])
      .order(:id)
  end
end