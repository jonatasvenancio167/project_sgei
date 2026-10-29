module Access
  class MemberSaveService < BaseService
    def initialize(church:, params:, performed_by:, user: nil, enable_access: false)
      @church, @params, @actor = church, params.to_h.stringify_keys, performed_by
      @user = user || church.users.build
      @new = @user.new_record?
      @enable_access = enable_access
    end

    def call
      can_grant = @actor.church_id == @church.id && @actor.can_access?("access", action: "manage")
      raise Pundit::NotAuthorizedError unless @actor.church_id == @church.id
      if @new
        raise Pundit::NotAuthorizedError unless UserPolicy.new(@actor, @user).create?
      else
        raise Pundit::NotAuthorizedError unless @user.church_memberships.exists?(church: @church) && (UserPolicy.new(@actor, @user).update? || can_grant)
      end
      requested = Array(@params["access_profile_ids"]).reject(&:blank?).map(&:to_s).uniq
      if !can_grant && (@params.key?("access_profile_ids") || @params.key?("role") || @params["access_enabled"] == "1")
        base = @church.access_profiles.find_by!(key: "member")
        raise Pundit::NotAuthorizedError unless @new && requested == [ base.id.to_s ] && @params["role"].blank? && @params["access_enabled"] != "1"
      end
      church_ids = @new ? [ @church.id ] : @user.church_memberships.pluck(:church_id) + [ @church.id ]
      if !@new && @user != @actor && church_ids.uniq.size > 1
        changes_identity = (@params.key?("email") && @params["email"] != @user.email) || @params["password"].present?
        if changes_identity && !church_ids.uniq.all? { |id| PermissionQuery.new(user: @actor, church: Church.find(id)).allowed?("access", action: "manage") }
          raise Pundit::NotAuthorizedError
        end
      end
      Access::Integrity.guard_many(church_ids) do
        before = @new ? {} : snapshot
        attrs = @params.slice("name", "email", "phone", "birth_date", "position")
        attrs["email"] = "sem-email-#{SecureRandom.hex(8)}@ekklesia.local" if @new && attrs["email"].blank?
        # Own-profile edits never change organizational metadata or access status.
        attrs.delete("position") if @user == @actor && !can_grant
        attrs["status"] = @params["status"] if @params.key?("status") && @user != @actor && can_grant && (@new || @user.church_memberships.count == 1)
        @user.assign_attributes(attrs)
        if can_grant && (@enable_access || @params["access_enabled"] == "1")
          password = @params["password"].presence || (@enable_access && @new ? SecureRandom.hex(16) : nil)
          if password
            @user.password = password
            @user.password_confirmation = @params["password_confirmation"].presence || password
          end
        end
        @user.save!
        @membership = @user.church_memberships.find_by!(church: @church)
        if can_grant && @params.key?("status") && @user != @actor
          @membership.update!(active: @params["status"] != "inactive")
        end
        if can_grant && (@enable_access || @params.key?("access_enabled"))
          enabled = @enable_access || @params["access_enabled"] == "1"
          raise Integrity::Violation, "Defina uma senha para habilitar o acesso" if enabled && @user.encrypted_password.blank?
          @membership.update!(access_enabled: enabled)
        end
        assign_profiles(requested) if can_grant && @params.key?("access_profile_ids")
        sync_ministries(can_grant)
        Audit::RecordService.call(church: @church, user: @actor, module_key: "access", action: @new ? "Cadastrou membro" : "Atualizou membro e acessos",
                                  detail: { user_id: @user.id, before: before, after: snapshot }.to_json)
      end
      Success(@user)
    rescue ActiveRecord::RecordInvalid => e
      @user.errors.add(:base, e.record.errors.full_messages.to_sentence) unless e.record == @user
      Failure(@user)
    rescue Integrity::Violation => e
      @user.errors.add(:base, e.message)
      Failure(@user)
    end

    private

    def assign_profiles(ids)
      profiles = @church.access_profiles.where(id: ids).to_a
      raise Pundit::NotAuthorizedError unless profiles.size == ids.size
      profiles = [ @church.access_profiles.find_by!(key: "member") ] if profiles.empty?
      current_ids = @membership.access_profiles.pluck(:id).sort
      target_ids = profiles.map(&:id).sort
      if @user == @actor && (target_ids - current_ids).any?
        raise Integrity::Violation, "Você não pode ampliar seus próprios privilégios"
      end
      if profiles.any? { |profile| profile.key == "leader" }
        led_ids = Array(@params["led_departament_ids"]).reject(&:blank?)
        if led_ids.empty? && !@user.memberchips.joins(:departament).where(role: :leader, departaments: { church_id: @church.id }).exists?
          raise Integrity::Violation, "Indique ao menos um ministério sob liderança"
        end
      end
      @membership.profile_assignments.where.not(access_profile_id: target_ids).destroy_all
      profiles.each { |profile| @membership.profile_assignments.find_or_create_by!(access_profile: profile, church: @church) }
    end

    def sync_ministries(can_grant)
      if @params.key?("departament_id") && @user != @actor
        department_id = @params["departament_id"].presence
        department = @church.departaments.find(department_id) if department_id
        if department
          @user.memberchips.find_or_create_by!(departament: department) { |link| link.role = :member }
        end
      end
      return unless @params.key?("led_departament_ids")
      raise Pundit::NotAuthorizedError unless can_grant
      ids = Array(@params["led_departament_ids"]).reject(&:blank?).map(&:to_i).uniq
      if @user == @actor
        current_led = @user.memberchips.where(role: :leader, departament_id: @church.departaments.select(:id)).pluck(:departament_id)
        raise Integrity::Violation, "Você não pode ampliar sua própria liderança" if (ids - current_led).any?
      end
      departments = @church.departaments.where(id: ids)
      raise Pundit::NotAuthorizedError unless departments.count == ids.size
      unless @membership.access_profiles.exists?(key: "leader") || ids.empty?
        raise Integrity::Violation, "Selecione o perfil Líder de ministério para conceder liderança"
      end
      @user.memberchips.where(departament_id: @church.departaments.select(:id)).where.not(departament_id: ids).update_all(role: 0)
      departments.each do |department|
        @user.memberchips.find_or_initialize_by(departament: department).tap { |link| link.update!(role: :leader) }
      end
    end

    def snapshot
      membership = @user.church_memberships.find_by(church: @church)
      { profile_ids: membership&.access_profiles&.pluck(:id), access_enabled: membership&.access_enabled,
        status: @user.status, led_departament_ids: @user.memberchips.where(role: :leader).pluck(:departament_id) }
    end
  end
end
