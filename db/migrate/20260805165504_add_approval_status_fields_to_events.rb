class AddApprovalStatusFieldsToEvents < ActiveRecord::Migration[8.0]
  # up/down em vez de change: o backfill de dados abaixo não é reversível
  # automaticamente.
  def up
    add_column :events, :status, :integer, null: false, default: 0
    add_column :events, :approved_by_id, :bigint
    add_column :events, :approved_at, :datetime
    add_column :events, :rejection_reason, :string
    add_column :events, :cancelled_at, :datetime
    add_column :events, :cancelled_by_id, :bigint
    add_column :events, :cancel_reason, :string

    add_index :events, :status
    add_index :events, :approved_by_id
    add_index :events, [ :church_id, :status ], name: "index_events_on_church_and_status"

    add_foreign_key :events, :users, column: :approved_by_id
    add_foreign_key :events, :users, column: :cancelled_by_id

    # Eventos existentes já estavam "no ar" sob o sistema antigo (sem fluxo
    # de aprovação). Tratá-los como aprovados evita que sumam de listagem/
    # calendário assim que os próximos passos passarem a filtrar por status.
    # 2 == Event#status enum :approved (definido junto no model).
    execute "UPDATE events SET status = 2"
  end

  def down
    remove_foreign_key :events, column: :cancelled_by_id
    remove_foreign_key :events, column: :approved_by_id
    remove_index :events, [ :church_id, :status ], name: "index_events_on_church_and_status"
    remove_index :events, :approved_by_id
    remove_index :events, :status

    remove_column :events, :cancel_reason
    remove_column :events, :cancelled_by_id
    remove_column :events, :cancelled_at
    remove_column :events, :rejection_reason
    remove_column :events, :approved_at
    remove_column :events, :approved_by_id
    remove_column :events, :status
  end
end
