class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :church, null: false, foreign_key: true
      t.string :title
      t.text :message
      t.integer :notification_type, default: 0

      t.timestamps
    end
  end
end
