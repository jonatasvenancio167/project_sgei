json.extract! notification, :id, :church_id, :title, :message, :notification_type, :created_at, :updated_at
json.url notification_url(notification, format: :json)
