module Settings
  class UserRemoveService < BaseService
    def initialize(user:, performed_by:)
      @user = user
      @performed_by = performed_by
    end

    def call
      if user == performed_by
        user.errors.add(:base, "Você não pode remover o seu próprio acesso")
        return Failure(user)
      end

      # Soft delete keeps schedules, events and audit history consistent.
      if user.update(deleted_at: Time.current, status: :inactive)
        Audit::RecordService.call(
          church: user.church, user: performed_by,
          module_key: "users", action: "Removeu usuário",
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
