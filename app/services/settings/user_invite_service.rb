module Settings
  class UserInviteService < BaseService
    def initialize(church:, params:, performed_by:)
      @church = church
      @params = params
      @performed_by = performed_by
    end

    def call
      user = church.users.build(params.except(:password, :password_confirmation))
      assign_password(user)
      user.role ||= :member

      if user.save
        Audit::RecordService.call(
          church: church, user: performed_by,
          module_key: "users", action: "Convidou usuário",
          detail: "#{user.name} (#{user.role_label})"
        )
        Success(user)
      else
        Failure(user)
      end
    end

    private

    attr_reader :church, :params, :performed_by

    def assign_password(user)
      if params[:password].present?
        user.password = params[:password]
        user.password_confirmation = params[:password_confirmation]
      else
        generated = SecureRandom.hex(8)
        user.password = generated
        user.password_confirmation = generated
      end
    end
  end
end
