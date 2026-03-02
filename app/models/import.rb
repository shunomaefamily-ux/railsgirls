class Import < ApplicationRecord
  belongs_to :person, optional: true  # ← 追加/変更
end
