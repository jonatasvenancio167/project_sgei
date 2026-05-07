class CreateFormResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :form_responses do |t|
      t.references :form, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :submitted_at

      t.timestamps
    end
  end
end
