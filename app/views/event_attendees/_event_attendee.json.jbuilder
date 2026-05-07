json.extract! event_attendee, :id, :created_at, :updated_at
json.url event_attendee_url(event_attendee, format: :json)
