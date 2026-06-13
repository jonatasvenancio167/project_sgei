class AddColorAndIconToDepartaments < ActiveRecord::Migration[8.0]
  def change
    add_column :departaments, :color, :string, default: "bg-blue-500 text-white"
    add_column :departaments, :icon, :string, default: "users"
  end
end
