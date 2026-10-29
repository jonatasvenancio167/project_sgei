module Settings
  class UserToggleStatusService < BaseService
    def initialize(user:, performed_by:)
      @user, @actor = user, performed_by
    end

    def call
      church = @actor.church
      raise Pundit::NotAuthorizedError unless @actor.can_access?("access", action: "manage") && @user.church_memberships.exists?(church: church)
      if @user == @actor
        @user.errors.add(:base, "Você não pode desativar o seu próprio acesso")
        return Failure(@user)
      end
      Access::Integrity.guard(church) do
        membership = @user.church_memberships.find_by!(church: church)
        membership.update!(active: !membership.active?)
        Audit::RecordService.call(church: church, user: @actor, module_key: "users", action: "Alterou situação do vínculo",
          detail: { user_id: @user.id, active: membership.active? }.to_json)
      end
      Success(@user)
    rescue ActiveRecord::RecordInvalid, Access::Integrity::Violation => e
      @user.errors.add(:base, e.message)
      Failure(@user)
    end
  end
end
