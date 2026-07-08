class AddDataToEscalaEntradas < ActiveRecord::Migration[8.0]
  def change
    add_column :escala_entradas, :data, :date
    add_index :escala_entradas, :data
  end
end
