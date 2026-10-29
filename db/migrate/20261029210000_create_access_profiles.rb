class CreateAccessProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :access_profiles do |t|
      t.references :church, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.string :normalized_name, null: false
      t.text :description, null: false
      t.boolean :standard, null: false, default: false
      t.references :parent_profile, foreign_key: { to_table: :access_profiles }
      t.timestamps
    end
    add_index :access_profiles, [:church_id, :key], unique: true
    add_index :access_profiles, [:church_id, :normalized_name], unique: true
    add_index :access_profiles, [:id, :church_id], unique: true
    create_table :church_memberships do |t|
      t.references :church, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :active, null: false, default: true
      t.boolean :access_enabled, null: false, default: false
      t.timestamps
    end
    add_index :church_memberships, [:church_id, :user_id], unique: true
    add_index :church_memberships, [:id, :church_id], unique: true
    create_table :profile_assignments do |t|
      t.references :church, null: false, foreign_key: true
      t.references :church_membership, null: false, foreign_key: true
      t.references :access_profile, null: false, foreign_key: true
      t.timestamps
    end
    add_index :profile_assignments, [:church_membership_id, :access_profile_id], unique: true, name: "index_unique_profile_assignment"
    add_foreign_key :profile_assignments, :church_memberships, column: [:church_membership_id, :church_id], primary_key: [:id, :church_id]
    add_foreign_key :profile_assignments, :access_profiles, column: [:access_profile_id, :church_id], primary_key: [:id, :church_id]
    add_reference :role_permissions, :access_profile, foreign_key: true
    change_column_null :role_permissions, :role, true
    add_column :role_permissions, :action_key, :string, null: false, default: "read"
    add_column :role_permissions, :scope_key, :string, null: false, default: "church"
    add_index :role_permissions, [:access_profile_id, :module_key, :action_key], unique: true, name: "index_profile_module_action"
    add_foreign_key :role_permissions, :access_profiles, column: [:access_profile_id, :church_id], primary_key: [:id, :church_id]
    add_column :churches, :profiles_provisioned_at, :datetime
    add_column :users, :position, :string
  end
end
