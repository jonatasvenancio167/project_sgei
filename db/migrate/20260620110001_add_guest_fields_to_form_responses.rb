class AddGuestFieldsToFormResponses < ActiveRecord::Migration[8.0]
  def change
    change_column_null :form_responses, :user_id, true
    add_column :form_responses, :token, :string
    add_column :form_responses, :guest_name, :string
    add_column :form_responses, :guest_email, :string
    add_column :form_responses, :guest_phone, :string
    add_index :form_responses, :token, unique: true
  end
end
