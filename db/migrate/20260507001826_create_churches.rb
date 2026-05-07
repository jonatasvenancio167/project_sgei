class CreateChurches < ActiveRecord::Migration[8.0]
  def change
    create_table :churches do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :email
      t.string :phone
      
      t.timestamps
    end

    add_index :churches, :slug, unique: true
  end
end
