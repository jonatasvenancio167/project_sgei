module ApplicationHelper
  include Pagy::Frontend

  # Whether the current user's role can access a module
  # (Configurações → Perfis e Permissões).
  def module_allowed?(module_key)
    return false unless current_user

    RolePermission.allowed?(
      church: current_user.church,
      role: current_user.role,
      module_key: module_key
    )
  end
end
