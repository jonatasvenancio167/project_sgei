class FormResponse < ApplicationRecord
  belongs_to :form
  belongs_to :user
end
