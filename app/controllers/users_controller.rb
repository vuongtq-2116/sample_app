class UsersController < ApplicationController
  before_action :logged_in_user, except: %i(new create)
  before_action :admin_user, only: :destroy
  before_action :load_user, except: %i(index new create)
  before_action :correct_user, only: %i(edit update)

  def index
    @users = User.paginate page: params[:page]
  end

  def new
    @user = User.new
  end

  def show; end

  def edit; end

  def create
    @user = User.new user_params
    if @user.save
      log_in @user
      flash[:success] = t ".welcome"
      redirect_to @user
    else
      render :new
    end
  end

  def update
    if @user.update user_params
      flash[:success] = t ".update_success"
      redirect_to @user
    else
      render :edit
    end
  end

  def destroy
    if @user.destroy
      flash[:success] = t ".deleted"
    else
      flash[:danger] = t ".cannot_deleted"
    end
    redirect_to users_url
  end

  private

  def user_params
    params.require(:user).permit User::ATTR_PARAMS
  end

  def load_user
    @user = User.find_by id: params[:id]
    return if @user

    flash[:danger] = t ".not_found_user"
    redirect_to root_url
  end

  def logged_in_user
    return if logged_in?

    store_location
    flash[:danger] = t ".require_login"
    redirect_to login_url
  end

  def correct_user
    redirect_to root_url unless current_user? @user
  end

  def admin_user
    return if current_user.is_admin?

    flash[:danger] = t ".not_admin"
    redirect_to root_url
  end
end
