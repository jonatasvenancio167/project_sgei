class CreateDepartaments < ActiveRecord::Migration[8.0]
  def change
    create_table :departaments do |t|
      t.references :church, null: false, foreign_key: true

      t.string :name, null: false
      t.string :description

      t.timestamps
    end

    add_index :departaments, :name
  end
end
