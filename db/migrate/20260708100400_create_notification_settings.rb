class CreateNotificationSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_settings do |t|
      t.references :church, null: false, foreign_key: true
      t.string  :event_key, null: false
      t.boolean :active, default: true, null: false
      t.integer :channel, default: 0, null: false

      t.timestamps
    end

    add_index :notification_settings, %i[church_id event_key], unique: true
  end
end
