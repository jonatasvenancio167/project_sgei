module RolePermissions
  class AllowedQuery
    def initialize(user:, module_key:, action: "read")
      @user, @module_key, @action = user, module_key, action
    end

    def call
      @user.can_access?(@module_key, action: @action)
    end
  end
end
