module WelcomeRecords
  class ConversionsController < ApplicationController
    before_action :set_welcome_record

    # PATCH /panel/welcome/:welcome_record_id/conversion
    def update
      @welcome_record.update!(became_member: !@welcome_record.became_member)
      notice = @welcome_record.became_member? ? t(".marked", name: @welcome_record.name) : t(".unmarked")
      redirect_to panel_welcome_path(preserve_filters), notice: notice, status: :see_other
    end

    private

    def set_welcome_record
      @welcome_record = current_user.church.welcome_records.find(params[:welcome_record_id])
      authorize @welcome_record, :toggle_member?
    end

    # Preserve current tab/filter params when redirecting back to index
    def preserve_filters
      params.permit(:tab, :q, :type, :service, :start_date, :end_date, :members_only, :page, :per).to_h
    end
  end
end
