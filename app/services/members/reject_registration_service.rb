module Members
  class RejectRegistrationService < BaseService
    def initialize(user:, performed_by:, reason:)
      @user = user
      @performed_by = performed_by
      @reason = reason
    end

    def call
      if reason.blank?
        user.errors.add(:base, "Motivo da recusa não pode ficar em branco")
        return Failure(user)
      end

      user.reject_registration!
      Audit::RecordService.call(
        church: user.church, user: performed_by,
        module_key: "members", action: "Recusou cadastro de membro", detail: "#{user.name} — #{reason}"
      )
      Success(user)
    rescue ActiveRecord::RecordInvalid
      Failure(user)
    end

    private

    attr_reader :user, :performed_by, :reason
  end
end
