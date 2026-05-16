class Notification < ApplicationRecord
  belongs_to :church
  has_many :user_notifications, dependent: :destroy
  has_many :users, through: :user_notifications
end
