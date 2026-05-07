class CreateFormFields < ActiveRecord::Migration[8.0]
  def change
    create_table :form_fields do |t|
      t.references :form, null: false, foreign_key: true

      t.string :label, null: false
      t.string :label_type, null: false
      t.boolean :required, default: false

      t.jsonb :options, default: {}
      t.integer :position, default: 0
      
      t.timestamps
    end

    add_index :form_fields, :type
    add_index :form_fields, :position
  end
end
