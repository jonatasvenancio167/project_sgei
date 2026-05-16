class Departament < ApplicationRecord
  belongs_to :church
  has_many :events, dependent: :destroy
  has_many :memberchips, dependent: :destroy
  has_many :users, through: :memberchips
end
