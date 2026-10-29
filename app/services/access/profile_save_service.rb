module Access
  class ProfileSaveService < BaseService
    def initialize(church:, params:, performed_by:, profile: nil)
      @church, @params, @actor = church, params.to_h.symbolize_keys, performed_by
      @profile = profile || church.access_profiles.build(key: "custom_#{SecureRandom.uuid}", parent_profile: church.access_profiles.find_by!(key: "member"))
    end

    def call
      raise Pundit::NotAuthorizedError unless @actor.can_access?("access", action: "manage") && @actor.church_id == @church.id
      raise Pundit::NotAuthorizedError unless @profile.church_id == @church.id
      before = @profile.attributes.slice("name", "description")
      @profile.update!(@params.slice(:name, :description))
      Audit::RecordService.call(church: @church, user: @actor, module_key: "access", action: "Salvou perfil",
                                detail: { profile_id: @profile.id, before: before, after: @profile.attributes.slice("name", "description") }.to_json)
      Success(@profile)
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record)
    rescue ActiveRecord::RecordNotUnique
      @profile.errors.add(:name, "já está em uso nesta igreja")
      Failure(@profile)
    end
  end
end
