class AddTimeAndRegistrationFieldsToEvents < ActiveRecord::Migration[8.0]
  def change
    # start_date/end_date continuam :date — start_time/end_time cobrem o
    # horário sem recast de coluna existente (docs/Ekklesia/telas/eventos.md §10.1).
    add_column :events, :start_time, :time
    add_column :events, :end_time, :time

    add_column :events, :registration_enabled, :boolean, null: false, default: false
    add_column :events, :registration_limit, :integer, default: 0
  end
end
