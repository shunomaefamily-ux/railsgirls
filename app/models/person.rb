class Person < ApplicationRecord
  has_many :medication_items, dependent: :destroy
  has_many :drug_products, through: :medication_items
end
