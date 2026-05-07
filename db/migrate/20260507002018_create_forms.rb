class CreateForms < ActiveRecord::Migration[8.0]
  def change
    create_table :forms do |t|
      t.references :church, null: false, foreign_key: true
      t.references :event, null: true, foreign_key: true
      
      t.string :title
      t.string :description
      
      t.boolean :active, default: true

      t.datetime :deleted_at

      t.timestamps
    end

    add_index :forms, :active
    add_index :forms, :deleted_at
  end
end
