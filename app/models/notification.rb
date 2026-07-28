class Notification < ApplicationRecord
  include BaseEntity

  has_many :user_notifications, dependent: :destroy
  has_many :users, through: :user_notifications

  enum :notification_type, { system: 0, event: 1, form_submission: 2, schedule: 3 }
end
