class CreateEventAttendees < ActiveRecord::Migration[8.0]
  def change
    create_table :event_attendees do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.string :guest_name
      t.string :guest_phone
      t.string :guest_email

      t.integer :status, default: 0

      t.timestamps
    end

    add_index :event_attendees, :event_id
    add_index :event_attendees, :user_id
    add_index :event_attendees, [:event_id, :user_id], unique: true
  end
end
