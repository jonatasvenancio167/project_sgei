class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :church, null: false, foreign_key: true
      t.references :departament, null: false, foreign_key: true

      t.string :title, null: false
      t.string :slug

      t.string :description
      t.string :thumbnail
      t.string :location

      t.date :start_date, null: false
      t.date :end_date, null: false

      t.references :created_by, 
                    foreign_key: {
                      to_table: :users
                    }

      t.integer :visibility, default: 0

      t.datetime :deleted_at

      t.timestamps
    end

    add_index :events, [:start_date, :end_date]
    add_index :events, :slug
    add_index :events, :deleted_at
  end
end
