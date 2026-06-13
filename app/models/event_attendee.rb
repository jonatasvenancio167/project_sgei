class EventAttendee < ApplicationRecord
  belongs_to :event, counter_cache: true

  belongs_to :user
end
