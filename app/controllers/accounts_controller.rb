# frozen_string_literal: true

# AccountsController
class AccountsController < ApplicationController
  def show; end

  def update
    if password_change?
      update_password
    else
      update_profile
    end
  end

  def destroy
    current_user.destroy
    terminate_session
    redirect_to new_session_path, notice: "Your account has been deleted."
  end

  private

  def password_change?
    params.dig(:user, :password).present? ||
      params.dig(:user, :password_confirmation).present? ||
      params.dig(:user, :current_password).present?
  end

  def theme_change?
    params.require(:user).keys == [ "theme" ]
  end

  def update_profile
    if current_user.update(profile_params)
      # The theme lives on <body>, outside the page-content stream target, so
      # the redirected page must be a full render for it to apply.
      flash[:_full_render] = true if theme_change?
      redirect_to account_path, notice: theme_change? ? "Theme updated." : "Account updated."
    else
      flash.now[:alert] = current_user.errors.full_messages.to_sentence
      render :show, status: :unprocessable_content
    end
  end

  def update_password
    unless current_user.authenticate(params.dig(:user, :current_password).to_s)
      flash.now[:alert] = "Current password is incorrect."
      return render :show, status: :unprocessable_content
    end

    if current_user.update(password_params)
      redirect_to account_path, notice: "Password updated."
    else
      flash.now[:alert] = current_user.errors.full_messages.to_sentence
      render :show, status: :unprocessable_content
    end
  end

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :birthdate, :theme)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
