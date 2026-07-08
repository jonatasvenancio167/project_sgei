class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :church, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :module_key, null: false
      t.string :action, null: false
      t.string :detail

      t.timestamps
    end

    add_index :audit_logs, %i[church_id created_at]
  end
end
