class UserNotificationsController < ApplicationController
  before_action :set_user_notification, only: %i[ show edit update destroy ]

  # GET /user_notifications or /user_notifications.json
  def index
    authorize UserNotification
    @user_notifications = policy_scope(UserNotification)
  end

  # GET /user_notifications/1 or /user_notifications/1.json
  def show
  end

  # GET /user_notifications/new
  def new
    @user_notification = UserNotification.new
    authorize @user_notification
  end

  # GET /user_notifications/1/edit
  def edit
  end

  # POST /user_notifications or /user_notifications.json
  def create
    @user_notification = UserNotification.new(user_notification_params)
    @user_notification.user ||= current_user
    authorize @user_notification

    respond_to do |format|
      if @user_notification.save
        format.html { redirect_to @user_notification, notice: t(".success") }
        format.json { render :show, status: :created, location: @user_notification }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user_notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /user_notifications/1 or /user_notifications/1.json
  def update
    respond_to do |format|
      if @user_notification.update(user_notification_params)
        format.html { redirect_to @user_notification, notice: t(".success"), status: :see_other }
        format.json { render :show, status: :ok, location: @user_notification }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user_notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_notifications/1 or /user_notifications/1.json
  def destroy
    @user_notification.destroy!

    respond_to do |format|
      format.html { redirect_to user_notifications_path, notice: t(".success"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_notification
      @user_notification = policy_scope(UserNotification).find(params.expect(:id))
      authorize @user_notification
    end

    # Only allow a list of trusted parameters through.
    def user_notification_params
      params.fetch(:user_notification, {})
    end
end
