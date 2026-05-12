class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.references :church, null: false, foreign_key: true

      t.string :name, null: false
      t.string :email, null: false
      t.string :phone

      t.integer :role, default: 2
      t.integer :status, default: 0

      t.datetime :deleted_at

      t.timestamps
    end

    add_index :users, :email
    add_index :users, :role
    add_index :users, :deleted_at
  end
end
