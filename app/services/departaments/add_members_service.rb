module Departaments
  class AddMembersService < BaseService
    def initialize(departament:, current_user:, params:)
      @departament, @current_user, @params = departament, current_user, params
    end

    def call
      raise Pundit::NotAuthorizedError unless DepartamentPolicy.new(@current_user, @departament).add_members?
      result = nil
      ActiveRecord::Base.transaction do
        result = case @params[:kind]
        when "existing" then add_existing
        when "new" then add_new
        else Failure(:invalid_kind)
        end
        raise ActiveRecord::Rollback if result.failure?
      end
      result
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record)
    end

    private

    def add_existing
      ids = Array(@params[:user_ids]).reject(&:blank?).map(&:to_i).uniq
      return Failure(:no_contact_selected) if ids.empty?
      valid_ids = ChurchMembership.where(church_id: @departament.church_id, user_id: ids, active: true).pluck(:user_id)
      raise Pundit::NotAuthorizedError unless valid_ids.sort == ids.sort
      count = 0
      ids.each do |id|
        link = @departament.memberchips.find_or_initialize_by(user_id: id)
        next if link.persisted?
        link.role = :member
        link.save!
        count += 1
      end
      audit(ids)
      Success(count)
    end

    def add_new
      result = Access::MemberSaveService.call(church: @current_user.church, performed_by: @current_user,
        params: { name: @params[:name], email: @params[:email], phone: @params[:phone], departament_id: @departament.id })
      return result if result.failure?
      user = result.value!
      make_leader = %w[1 true].include?(@params[:make_leader].to_s)
      user.memberchips.find_by!(departament: @departament).update!(role: make_leader ? :leader : :member)
      audit([ user.id ])
      Success(user)
    end

    def audit(ids)
      Audit::RecordService.call(church: @current_user.church, user: @current_user, module_key: "access",
        action: "Vinculou participantes ao ministério", detail: { departament_id: @departament.id, user_ids: ids, leadership: @params[:make_leader] }.to_json)
    end
  end
end
