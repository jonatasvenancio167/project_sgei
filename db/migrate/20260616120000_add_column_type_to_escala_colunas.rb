class AddColumnTypeToEscalaColunas < ActiveRecord::Migration[8.0]
  def change
    add_column :escala_colunas, :column_type, :string, null: false, default: "text"
  end
end
