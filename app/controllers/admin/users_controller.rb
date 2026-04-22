class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  def index
    @users = User.order(:email_address)
  end

  def show; end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: "User created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    attrs = user_params
    attrs = attrs.reject { |k, v| k == "password" && v.blank? }
    if @user.update(attrs)
      redirect_to admin_users_path, notice: "User updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == Current.user
      redirect_to admin_users_path, alert: "You cannot delete your own account."
    else
      @user.destroy
      redirect_to admin_users_path, notice: "User deleted."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted = params.require(:user).permit(:email_address, :password, :password_confirmation)
    # Admin role is assigned explicitly only in admin-facing CRUD (not via user self-service)
    permitted[:admin] = params.dig(:user, :admin) == "1"
    permitted
  end
end
