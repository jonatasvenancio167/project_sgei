class CreateUserNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :user_notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :notification, null: false, foreign_key: true

      t.boolean :read, default: false

      t.datetime :sent_at

      t.timestamps
    end

    add_index :user_notifications, :read
  end
end
