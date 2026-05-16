class Form < ApplicationRecord
  belongs_to :church
  belongs_to :event, optional: true
  has_many :form_fields, dependent: :destroy
  has_many :form_responses, dependent: :destroy
end
