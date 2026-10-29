class EventAttendee < ApplicationRecord
  validate do
    if user && event && !user.church_memberships.exists?(church_id: event.church_id)
      errors.add(:user, "deve pertencer à igreja do evento")
    end
  end
  belongs_to :event, counter_cache: true

  belongs_to :user
end
