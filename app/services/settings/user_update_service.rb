module Settings
  class UserUpdateService < BaseService
    def initialize(user:, params:, performed_by:)
      @user = user
      @params = params
      @performed_by = performed_by
    end

    def call
      user.assign_attributes(params.except(:password, :password_confirmation))
      assign_password if params[:password].present?

      if user.save
        Audit::RecordService.call(
          church: user.church, user: performed_by,
          module_key: "users", action: "Editou usuário",
          detail: "#{user.name} (#{user.role_label})"
        )
        Success(user)
      else
        Failure(user)
      end
    end

    private

    attr_reader :user, :params, :performed_by

    def assign_password
      user.password = params[:password]
      user.password_confirmation = params[:password_confirmation]
    end
  end
end
