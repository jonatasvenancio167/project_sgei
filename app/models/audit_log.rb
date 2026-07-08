class AuditLog < ApplicationRecord
  MODULES = {
    "settings"      => "Configurações",
    "congregations" => "Congregações",
    "users"         => "Usuários",
    "permissions"   => "Permissões",
    "notifications" => "Notificações"
  }.freeze

  belongs_to :church
  belongs_to :user, optional: true

  validates :module_key, presence: true
  validates :action, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  def module_label
    MODULES.fetch(module_key, module_key.humanize)
  end

  def user_name
    user&.name || "Sistema"
  end
end
