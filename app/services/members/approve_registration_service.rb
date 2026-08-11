module Members
  class ApproveRegistrationService < BaseService
    def initialize(user:, performed_by:)
      @user = user
      @performed_by = performed_by
    end

    def call
      user.approve_registration!
      Audit::RecordService.call(
        church: user.church, user: performed_by,
        module_key: "members", action: "Aprovou cadastro de membro", detail: user.name
      )
      Success(user)
    rescue ActiveRecord::RecordInvalid
      Failure(user)
    end

    private

    attr_reader :user, :performed_by
  end
end
