class AddFormResponseToFormAnswers < ActiveRecord::Migration[8.0]
  def change
    add_reference :form_answers, :form_response, null: true, foreign_key: true
  end
end
