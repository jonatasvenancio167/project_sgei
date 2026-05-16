class Event < ApplicationRecord
  belongs_to :church
  belongs_to :departament
  belongs_to :creator, class_name: "User", foreign_key: "created_by_id", optional: true
  has_many :event_attendees, dependent: :destroy
  has_many :users, through: :event_attendees
  has_one :form, dependent: :destroy

  enum :visibility, { public_event: 0, member_only: 1 }
end
