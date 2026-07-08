class CreateEscalaParticipacoes < ActiveRecord::Migration[8.0]
  def change
    create_table :escala_participacoes do |t|
      t.references :escala_entrada, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :escala_coluna, null: false, foreign_key: true
      t.datetime :notificado_em
      t.datetime :lembrete_7d_em
      t.datetime :lembrete_3d_em
      t.datetime :lembrete_1d_em
      t.timestamps
    end

    add_index :escala_participacoes,
              [:escala_entrada_id, :user_id, :escala_coluna_id],
              unique: true,
              name: "index_escala_participacoes_unicidade"
  end
end
