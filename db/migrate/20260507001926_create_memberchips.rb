class CreateMemberchips < ActiveRecord::Migration[8.0]
  def change
    create_table :memberchips do |t|
      t.references :user, null: false, foreign_key: true
      t.references :departament, null: false, foreign_key: true

      t.integer :role, default: 0

      t.timestamps
    end

    add_index :memberchips, [:user_id, :departament_id], unique: true
  end
end
