class Church < ApplicationRecord
  has_many :departaments, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :forms, dependent: :destroy
  has_many :notifications, dependent: :destroy
end
