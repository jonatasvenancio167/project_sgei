class AddAddressToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :address, foreign_key: true
  end
end
