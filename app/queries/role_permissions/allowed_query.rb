module RolePermissions
  # Whether a role can access a module, per the per-church permission matrix
  # (Configurações → Perfis e Permissões). Admin always has full access.
  class AllowedQuery
    def initialize(church:, role:, module_key:)
      @church = church
      @role = role
      @module_key = module_key
    end

    def call
      return true if role.to_s == "admin"

      permission = RolePermission.find_by(church: church, role: role, module_key: module_key)
      permission.nil? || permission.allowed?
    end

    private

    attr_reader :church, :role, :module_key
  end
end
