class MakeDepartamentIdOptionalOnEvents < ActiveRecord::Migration[8.0]
  def change
    # nil == "Geral" (todos os departamentos) — já é o valor assumido por
    # CalendarController#index e EventDecorator#department_name.
    change_column_null :events, :departament_id, true
  end
end
