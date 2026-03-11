class Api::PeopleController < ApplicationController
  def index
    people = Person.order(:id)

    render json: {
      people: people.map do |person|
        {
          id: person.id,
          name: person.name
        }
      end
    }
  end
end