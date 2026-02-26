class ImportsController < ApplicationController
  def scan
    @person = Person.find(params[:person_id])
  end

  def create
    @person = Person.find(params[:person_id])
    import = @person.imports.build(import_params)

    if import.save
      head :created
    else
      render json: { errors: import.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def import_params
    params.require(:import).permit(:raw_text, :source)
  end
end