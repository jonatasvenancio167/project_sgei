module SettingsHelper
  INPUT_CLASSES = "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring".freeze

  SECTIONS = [
    { key: "church",        label: "Minha Instituição",   icon: "building-2",   description: "Identidade, dados e endereço" },
    { key: "congregations", label: "Congregações",        icon: "church",       description: "Filiais e pontos de pregação" },
    { key: "users",         label: "Usuários e Acesso",   icon: "users",        description: "Convidar e gerenciar acessos" },
    { key: "permissions",   label: "Perfis e Permissões", icon: "shield-check", description: "Controle por módulo" },
    { key: "notifications", label: "Notificações",        icon: "bell",         description: "Canais e eventos" },
    { key: "audit",         label: "Auditoria",           icon: "scroll-text",  description: "Histórico de ações" },
    { key: "integrations",  label: "Integrações",         icon: "plug",         description: "Serviços externos" }
  ].freeze

  def settings_input_classes(extra = nil)
    [INPUT_CLASSES, extra].compact.join(" ")
  end

  def settings_status_badge(active, active_label: "Ativa", inactive_label: "Inativa")
    if active
      tag.span(active_label, class: "inline-flex items-center rounded-full bg-emerald-600/15 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 dark:text-emerald-400")
    else
      tag.span(inactive_label, class: "inline-flex items-center rounded-full bg-muted px-2.5 py-0.5 text-xs font-semibold text-muted-foreground")
    end
  end
end
