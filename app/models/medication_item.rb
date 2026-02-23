class MedicationItem < ApplicationRecord
  belongs_to :person
  belongs_to :drug_product
end
