class PeopleController < ApplicationController
  def show
    @person = Person.find(params[:id])
    @latest_import = @person.imports.order(id: :desc).first
  end
end