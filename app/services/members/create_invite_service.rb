module Members
  # Generates a "Convite de Membro" link (docs/Ekklesia/telas/membros.md §7.3).
  class CreateInviteService < BaseService
    def initialize(church:, created_by:, params:)
      @church = church
      @created_by = created_by
      @params = params
    end

    def call
      invite = church.member_invites.build(
        created_by: created_by,
        note: params[:note],
        max_uses: params[:max_uses],
        expires_at: expires_at
      )

      return Failure(invite) unless invite.save

      Audit::RecordService.call(
        church: church, user: created_by,
        module_key: "members", action: "Gerou convite de membro", detail: invite.note
      )

      Success(invite)
    end

    private

    attr_reader :church, :created_by, :params

    def expires_at
      window = MemberInvite::EXPIRES_IN_OPTIONS[params[:expires_in]]
      window ? window.from_now : nil
    end
  end
end
