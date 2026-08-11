class CreateMemberInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :member_invites do |t|
      t.references :church,     null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.string   :token,      null: false
      t.string   :note
      t.integer  :max_uses,   null: false, default: 1
      t.integer  :uses_count, null: false, default: 0
      t.integer  :status,     null: false, default: 0
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :member_invites, :token, unique: true
    add_index :member_invites, :status
    add_index :member_invites, :expires_at
  end
end
