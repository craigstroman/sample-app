class PasswordResetsController < ApplicationController
  before_action :get_user, only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]
  def new
  end

  def create
  	@user = User.find_by(email: params[:password_reset][:email].downcase)

      captcha_message = "The Captcha is required."
      
      if verify_recaptcha
      	if @user && @user.provider.nil?
                  @user.create_reset_digest
      		@user.send_password_reset_email
      		flash[:info] = "Email sent with password reset instructions."
      		redirect_to root_url
      	else
      		flash.now[:danger] = "Email address not found."
      		render 'new'
      	end
      else
        flash.delete(:recaptcha_error)
        flash.now[:danger] = captcha_message
        render 'new'
      end

  end

  def edit
  end

  def update
    if params[:user][:password].empty?
      @user.errors.add(:password, "Can't be empty.")
      render 'edit'
    elsif @user.update_attributes(user_params)
      log_in @user
      @user.update_attribute(:reset_digest, nil)
      flash[:success] = "Password has been reset."
      redirect_to @user
    else
      render 'edit'
    end
  end

  private

    def user_params
      params.require(:user).permit(:password, :password_confirmation)
    end

    # Before filters
    def get_user
      @user = User.find_by(email: params[:email])
    end

    # Confirms a valid user.
    def valid_user
      unless (@user && @user.activated? && @user.authenticated?(:reset, params[:id]))
        redirect_to root_url
      end
    end

    def check_expiration
      if @user.password_reset_expired?
        flash[:danger] = "Password reset has expired.  Please request a new reset."
        redirect_to new_password_reset_url
      end
    end
end
