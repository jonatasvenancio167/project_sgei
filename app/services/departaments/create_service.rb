module Departaments
  # Creates a departament and links the initial members chosen in the
  # "Novo departamento" modal, promoting the chosen leader's role.
  class CreateService < BaseService
    def initialize(church:, params:, member_ids:, leader_id:)
      @church = church
      @params = params
      @member_ids = Array(member_ids).map(&:to_i)
      @leader_id = leader_id.presence&.to_i
    end

    def call
      departament = church.departaments.build(params)
      return Failure(departament) unless departament.save

      member_ids.each { |user_id| link_member(departament, user_id) }
      Success(departament)
    end

    private

    attr_reader :church, :params, :member_ids, :leader_id

    def link_member(departament, user_id)
      role = user_id == leader_id ? :leader : :member
      departament.memberchips.create!(user_id: user_id, role: role)
      promote_to_leader(user_id) if role == :leader
    end

    def promote_to_leader(user_id)
      user = User.find(user_id)
      user.update!(role: :leader) unless user.admin?
    end
  end
end
