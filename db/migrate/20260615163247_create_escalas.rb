class CreateEscalas < ActiveRecord::Migration[8.0]
  def change
    create_table :escalas do |t|
      t.references :church, null: false, foreign_key: true
      t.references :departament, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false, default: "bg-blue-500 text-white"

      t.timestamps
    end
  end
end
