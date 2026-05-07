json.extract! form_response, :id, :form_id, :user_id, :submitted_at, :created_at, :updated_at
json.url form_response_url(form_response, format: :json)
