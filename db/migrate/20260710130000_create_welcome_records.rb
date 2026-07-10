class CreateWelcomeRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :welcome_records do |t|
      t.references :church, null: false, foreign_key: true
      t.references :registered_by, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.integer :visitor_type, default: 0, null: false
      t.string :congregation
      t.string :city
      t.string :phone
      t.string :service, null: false
      t.text :notes
      t.boolean :became_member, default: false, null: false

      t.timestamps
    end

    # History is always listed and filtered per church, newest first.
    add_index :welcome_records, [ :church_id, :created_at ]
  end
end
