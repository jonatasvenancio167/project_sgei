class FormAnswer < ApplicationRecord
  belongs_to :form
  belongs_to :form_field, optional: true
  belongs_to :form_response, optional: true
end
