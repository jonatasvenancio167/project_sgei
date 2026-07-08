class AddDepartamentAndLimitToForms < ActiveRecord::Migration[8.0]
  def change
    add_reference :forms, :departament, null: true, foreign_key: true
    add_column :forms, :limit, :integer
  end
end
