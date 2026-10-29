module ApplicationHelper
  include Pagy::Frontend

  # Whether the current user's role can access a module
  # (Configurações → Perfis e Permissões).
  def module_allowed?(module_key)
    return false unless current_user

    current_user.can_access?(module_key)
  end
end
