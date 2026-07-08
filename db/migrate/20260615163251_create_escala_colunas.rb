class CreateEscalaColunas < ActiveRecord::Migration[8.0]
  def change
    create_table :escala_colunas do |t|
      t.references :escala, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :escala_colunas, [:escala_id, :position]
  end
end
