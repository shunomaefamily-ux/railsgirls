class MedicationItem < ApplicationRecord
  belongs_to :person
  belongs_to :drug_product

  has_many :medication_lots, dependent: :destroy
  has_many :intake_logs, dependent: :destroy
end
