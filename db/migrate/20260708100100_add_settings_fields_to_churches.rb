class AddSettingsFieldsToChurches < ActiveRecord::Migration[8.0]
  def change
    change_table :churches, bulk: true do |t|
      t.string  :display_name
      t.string  :cnpj
      t.string  :website
      t.date    :founded_at
      t.string  :timezone, default: "America/Fortaleza", null: false
      t.string  :primary_color, default: "#4f6e5d", null: false
      t.integer :church_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.string  :responsible_name
      t.references :address, foreign_key: true
      t.references :parent_church, foreign_key: { to_table: :churches }
    end
  end
end
