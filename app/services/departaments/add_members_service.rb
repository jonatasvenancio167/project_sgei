module Departaments
  # Links members to a departament, either picking someone already
  # registered in the church or creating a brand new member on the fly.
  class AddMembersService < BaseService
    def initialize(departament:, current_user:, params:)
      @departament = departament
      @current_user = current_user
      @params = params
    end

    def call
      case params[:kind]
      when "existing" then add_existing
      when "new"       then add_new
      else Failure(:invalid_kind)
      end
    end

    private

    attr_reader :departament, :current_user, :params

    def add_existing
      user_ids = Array(params[:user_ids]).map(&:to_i)
      return Failure(:no_contact_selected) if user_ids.empty?

      added_count = user_ids.count do |u_id|
        departament.memberchips.build(user_id: u_id, role: :member).save
      end
      Success(added_count)
    end

    def add_new
      make_leader = params[:make_leader] == "1" || params[:make_leader] == "true"
      user = find_or_build_user(make_leader)

      memberchip = departament.memberchips.build(user: user, role: make_leader ? :leader : :member)
      memberchip.save ? Success(user) : Failure(memberchip)
    end

    def find_or_build_user(make_leader)
      user = current_user.church.users.find_by(id: params[:user_ids])
      return user_with_leader_role(user, make_leader) if user

      password = SecureRandom.hex(8)
      User.create!(
        name: params[:name], email: params[:email].presence, phone: params[:phone],
        password: password, password_confirmation: password,
        church: current_user.church, role: make_leader ? :leader : :member
      )
    end

    def user_with_leader_role(user, make_leader)
      user.update!(role: :leader) if make_leader && !user.admin?
      user
    end
  end
end
