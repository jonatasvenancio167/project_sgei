class Event < ApplicationRecord
  enum visibility: { public_event: 0, member_only: 1 }
end
