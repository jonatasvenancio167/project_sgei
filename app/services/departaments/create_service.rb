module Departaments
  # Creates a departament and links the initial members chosen in the
  # "Novo departamento" modal. Organizational leadership does not grant an access profile.
  class CreateService < BaseService
    def initialize(church:, params:, member_ids:, leader_id:, performed_by:)
      @performed_by = performed_by
      @church = church
      @params = params
      @member_ids = Array(member_ids).reject(&:blank?).map(&:to_i).uniq
      @leader_id = leader_id.presence&.to_i
    end

    def call
      raise Pundit::NotAuthorizedError unless @performed_by.church_id == church.id && DepartamentPolicy.new(@performed_by, Departament).create?
      valid_ids = ChurchMembership.where(church: church, user_id: member_ids).pluck(:user_id)
      raise Pundit::NotAuthorizedError unless valid_ids.sort == member_ids.uniq.sort
      departament = church.departaments.build(params)
      return Failure(departament) unless departament.save

      member_ids.each { |user_id| link_member(departament, user_id) }
      Audit::RecordService.call(church: church, user: @performed_by, module_key: "access", action: "Criou ministério e vínculos",
        detail: { departament_id: departament.id, member_ids: member_ids, leader_id: leader_id }.to_json)
      Success(departament)
    end

    private

    attr_reader :church, :params, :member_ids, :leader_id

    def link_member(departament, user_id)
      role = user_id == leader_id ? :leader : :member
      departament.memberchips.create!(user_id: user_id, role: role)
    end
  end
end
