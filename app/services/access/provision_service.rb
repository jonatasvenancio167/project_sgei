module Access
  class ProvisionService < BaseService
    PROFILES = {
      "member" => [ "Membro", "Agenda, inscrições, escalas e cadastro próprios." ],
      "volunteer" => [ "Voluntário", "Participação nas equipes e escalas às quais está vinculado." ],
      "leader" => [ "Líder de ministério", "Organização dos ministérios explicitamente liderados." ],
      "secretary" => [ "Secretaria", "Gestão cadastral, eventos, inscrições e acolhimento." ],
      "finance" => [ "Financeiro / Tesouraria", "Perfil financeiro; módulo financeiro ainda indisponível." ],
      "pastor" => [ "Pastoral", "Consulta de informações para acompanhamento da comunidade." ],
      "admin" => [ "Administrador da igreja", "Administração de configurações, usuários, perfis e permissões." ]
    }.freeze

    def initialize(church:)
      @church = church
    end

    def call
      @church.with_lock do
        PROFILES.each do |key, (name, description)|
          @church.access_profiles.find_or_create_by!(key: key) do |profile|
            profile.name = name
            profile.description = description
            profile.standard = true
            profile.parent_profile = @church.access_profiles.find_by(key: "member") unless key == "member"
          end
        end
        grant("member", "calendar", "read", "audience")
        grant("member", "events", "read", "audience")
        grant("member", "schedules", "read", "own")
        grant("member", "forms", "read", "own")
        grant("member", "forms", "manage", "own")
        %w[read manage].each { |action| grant("member", "members", action, "own") }
        grant("volunteer", "departments", "read", "team")
        grant("volunteer", "schedules", "read", "team")
        %w[departments schedules members].each do |mod|
          grant("leader", mod, "read", mod == "members" ? "led" : "team")
          grant("leader", mod, "manage", "led") unless mod == "members"
        end
        %w[calendar events departments members birthdays welcome forms].each do |mod|
          grant("secretary", mod, "read", %w[members departments forms birthdays].include?(mod) ? "hierarchy" : "church")
          grant("secretary", mod, "manage", "church") unless %w[calendar birthdays].include?(mod)
        end
        %w[members departments schedules birthdays].each { |mod| grant("pastor", mod, "read", "church") }
        RolePermission::MODULES.each_key do |mod|
          grant("admin", mod, "read", %w[members departments forms birthdays].include?(mod) ? "hierarchy" : "church")
          grant("admin", mod, "manage", "church")
        end
        @church.update_column(:profiles_provisioned_at, Time.current)
      end
      Success(@church.access_profiles)
    end

    private

    def grant(key, mod, action, scope)
      profile = @church.access_profiles.find_by!(key: key)
      profile.role_permissions.find_or_create_by!(module_key: mod, action_key: action) do |permission|
        permission.church = @church
        permission.scope_key = scope
        permission.allowed = true
      end
    end
  end
end
