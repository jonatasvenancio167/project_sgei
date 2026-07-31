module Settings
  class UserToggleStatusService < BaseService
    def initialize(user:, performed_by:)
      @user = user
      @performed_by = performed_by
    end

    def call
      if user == performed_by
        user.errors.add(:base, "Você não pode desativar o seu próprio acesso")
        return Failure(user)
      end

      new_status = user.status_active? ? "inactive" : "active"

      if user.update(status: new_status)
        Audit::RecordService.call(
          church: user.church, user: performed_by,
          module_key: "users",
          action: new_status == "active" ? "Ativou usuário" : "Desativou usuário",
          detail: user.name
        )
        Success(user)
      else
        Failure(user)
      end
    end

    private

    attr_reader :user, :performed_by
  end
end
