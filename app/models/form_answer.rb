class FormAnswer < ApplicationRecord
  validate do
    errors.add(:form_response, :invalid) if form_response && form_response.form_id != form_id
    errors.add(:form_field, :invalid) if form_field && form_field.form_id != form_id
  end
  belongs_to :form
  belongs_to :form_field, optional: true
  belongs_to :form_response, optional: true
end
