class CreateIntegrations < ActiveRecord::Migration[8.0]
  def change
    create_table :integrations do |t|
      t.references :church, null: false, foreign_key: true

      t.string :provider, null: false
      t.string :api_key
      t.boolean :active, default: false
      
      t.timestamps
    end
  end
end
