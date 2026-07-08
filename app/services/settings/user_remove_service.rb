module Settings
  class UserRemoveService
    Result = Struct.new(:success?, :user, :errors, keyword_init: true)

    def initialize(user:, performed_by:)
      @user = user
      @performed_by = performed_by
    end

    def call
      if user == performed_by
        user.errors.add(:base, "Você não pode remover o seu próprio acesso")
        return Result.new(success?: false, user: user, errors: user.errors)
      end

      # Soft delete keeps schedules, events and audit history consistent.
      if user.update(deleted_at: Time.current, status: :inactive)
        Audit::RecordService.new(
          church: user.church, user: performed_by,
          module_key: "users", action: "Removeu usuário",
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
