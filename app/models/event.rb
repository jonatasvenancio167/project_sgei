class Event < ApplicationRecord
  belongs_to :church
  belongs_to :departament
  belongs_to :creator, class_name: "User", foreign_key: "created_by_id", optional: true
  has_many :event_attendees, dependent: :destroy
  has_many :users, through: :event_attendees
  has_one :form, dependent: :destroy

  enum :visibility, { private_event: 0, member_only: 1, public_event: 2 }

  def self.ransackable_attributes(auth_object = nil)
    %w[title location description start_date visibility departament_id event_attendees_count]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[departament event_attendees]
  end

  def visibility_label
    case visibility
    when "private_event" then "Privada"
    when "member_only" then "Membros"
    when "public_event" then "Pública"
    else visibility&.capitalize
    end
  end
end
