module Departaments
  class MembersController < ApplicationController
    before_action :set_departament

    # POST /departaments/:departament_id/members
    def create
      result = Departaments::AddMembersService.call(
        departament: @departament, current_user: current_user, params: member_params
      )

      case result
      in Success(Integer => count)
        redirect_to departaments_path, notice: t(".linked", count: count)
      in Success(User => user)
        redirect_to departaments_path, notice: t(".added", name: user.name)
      in Failure(:no_contact_selected)
        redirect_to departaments_path, alert: t(".select_contact")
      in Failure(:invalid_kind)
        redirect_to departaments_path
      in Failure(memberchip)
        redirect_to departaments_path, alert: memberchip.errors.full_messages.to_sentence
      end
    end

    private

    def set_departament
      @departament = policy_scope(Departament).find(params[:departament_id])
      authorize @departament, :add_members?
    end

    def member_params
      params.permit(:kind, :name, :email, :phone, :make_leader, user_ids: [])
    end
  end
end
