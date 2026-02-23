class DrugProduct < ApplicationRecord
  has_many :medication_items, dependent: :destroy
  has_many :people, through: :medication_items
end