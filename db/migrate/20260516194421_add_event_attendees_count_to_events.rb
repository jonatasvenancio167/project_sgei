class AddEventAttendeesCountToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :event_attendees_count, :integer
  end
end
