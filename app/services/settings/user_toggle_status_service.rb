module Settings
  class UserToggleStatusService
    Result = Struct.new(:success?, :user, :errors, keyword_init: true)

    def initialize(user:, performed_by:)
      @user = user
      @performed_by = performed_by
    end

    def call
      if user == performed_by
        user.errors.add(:base, "Você não pode desativar o seu próprio acesso")
        return Result.new(success?: false, user: user, errors: user.errors)
      end

      new_status = user.status_active? ? "inactive" : "active"

      if user.update(status: new_status)
        Audit::RecordService.new(
          church: user.church, user: performed_by,
          module_key: "users",
          action: new_status == "active" ? "Ativou usuário" : "Desativou usuário",
          detail: user.name
        ).call
        Result.new(success?: true, user: user)
      else
        Result.new(success?: false, user: user, errors: user.errors)
      end
    end

    private

    attr_reader :user, :performed_by
  end
end
