class CreateFormAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :form_answers do |t|
      t.references :form, null: false, foreign_key: true
      t.references :form_field, null: true, foreign_key: true

      t.text :value

      t.timestamps
    end

    add_index :form_answers, :value
  end
end
