class CreateEscalaEntradas < ActiveRecord::Migration[8.0]
  def change
    create_table :escala_entradas do |t|
      t.references :escala, null: false, foreign_key: true
      t.string :mes, null: false
      t.integer :posicao, null: false, default: 0
      t.jsonb :valores, null: false, default: {}

      t.timestamps
    end

    add_index :escala_entradas, [:escala_id, :mes]
  end
end
