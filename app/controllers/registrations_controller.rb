class RegistrationsController < Devise::RegistrationsController
  layout "public"

  # GET /users/sign_up
  def new
    @user = User.new(address: Address.new)
    @church = Church.new(address: Address.new)
  end

  # POST /users
  def create
    result = Registrations::SignUpService.call(
      user_params: user_params,
      church_params: church_params,
      terms_accepted: terms_accepted?
    )

    case result
    in Success(user)
      sign_in(user)
      redirect_to root_path, notice: t(".success")
    in Failure(Church => church)
      @church = church
      @user = User.new(user_params.except(:password, :password_confirmation))
      render :new, status: :unprocessable_entity
    in Failure(User => user)
      @user = user
      @church = Church.new(church_params)
      render :new, status: :unprocessable_entity
    in Failure(:terms_not_accepted)
      @user = User.new(user_params.except(:password, :password_confirmation))
      @church = Church.new(church_params)
      @user.errors.add(:base, :terms_not_accepted)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :name, :birth_date, :email, :phone, :password, :password_confirmation,
      address_attributes: %i[street number complement neighborhood city state zip_code]
    )
  end

  def church_params
    params.require(:church).permit(
      :name, :display_name, :church_type, :cnpj, :founded_at, :email, :phone, :website,
      :responsible_name, :timezone, :logo,
      address_attributes: %i[street number complement neighborhood city state zip_code]
    )
  end

  def terms_accepted?
    params[:terms_accepted] == "1"
  end
end
