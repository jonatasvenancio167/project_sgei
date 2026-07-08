class RenameEscalaTablesToEnglish < ActiveRecord::Migration[8.0]
  def change
    rename_table :escalas, :schedules
    rename_table :escala_colunas, :schedule_columns
    rename_table :escala_entradas, :schedule_entries
    rename_table :escala_participacoes, :schedule_assignments

    rename_column :schedule_columns, :escala_id, :schedule_id
    rename_column :schedule_entries, :escala_id, :schedule_id
    rename_column :schedule_entries, :mes, :month
    rename_column :schedule_entries, :posicao, :position
    rename_column :schedule_entries, :valores, :cell_values
    rename_column :schedule_entries, :data, :date

    rename_column :schedule_assignments, :escala_entrada_id, :schedule_entry_id
    rename_column :schedule_assignments, :escala_coluna_id, :schedule_column_id
    rename_column :schedule_assignments, :notificado_em, :notified_at
    rename_column :schedule_assignments, :lembrete_7d_em, :reminder_7d_sent_at
    rename_column :schedule_assignments, :lembrete_3d_em, :reminder_3d_sent_at
    rename_column :schedule_assignments, :lembrete_1d_em, :reminder_1d_sent_at

    rename_index :schedule_assignments, "index_escala_participacoes_unicidade", "index_schedule_assignments_uniqueness"
  end
end
