class CreateRolePermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :role_permissions do |t|
      t.references :church, null: false, foreign_key: true
      t.integer :role, null: false
      t.string  :module_key, null: false
      t.boolean :allowed, default: true, null: false

      t.timestamps
    end

    add_index :role_permissions, %i[church_id role module_key], unique: true
  end
end
