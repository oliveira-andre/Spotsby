class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :block_users

  helper_method :current_user

  private

  def current_user
    Current.user
  end

  def block_users
    return unless authenticated?

    redirect_to new_session_path, alert: "Your account has been blocked." if current_user.blocked?
  end
end
