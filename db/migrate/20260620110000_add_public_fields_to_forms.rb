class AddPublicFieldsToForms < ActiveRecord::Migration[8.0]
  def change
    add_column :forms, :slug, :string
    add_column :forms, :banner_url, :string
    add_index :forms, :slug, unique: true
  end
end
