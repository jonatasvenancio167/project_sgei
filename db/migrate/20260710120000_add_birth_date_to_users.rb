class AddBirthDateToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :birth_date, :date

    # Birthday lookups filter by month/day regardless of year, so a plain
    # index on birth_date would never be used by those queries.
    add_index :users, "EXTRACT(MONTH FROM birth_date), EXTRACT(DAY FROM birth_date)",
              name: "index_users_on_birth_date_month_day"
  end
end
