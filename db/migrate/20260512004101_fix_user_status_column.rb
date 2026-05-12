class FixUserStatusColumn < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:users, :status)
      add_column :users, :status, :integer, default: 0
    end
    
    change_column :users, :status, :integer, default: 0, using: 'status::integer' rescue nil
    
    if column_exists?(:users, :active)
      remove_column :users, :active, :boolean
    end
  end
end
