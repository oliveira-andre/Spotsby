class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include Pagy::Method

  DEFAULT_PER_PAGE = 10

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :block_users

  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  helper_method :current_user

  def default_render(*args)
    if flash[:_full_render]
      render action_name, formats: :html
    elsif request.format.turbo_stream? && !turbo_stream_template_exists?
      body = render_to_string(action_name, layout: false)
      render turbo_stream: turbo_stream.update("page-content", body)
    else
      super
    end
  end

  private

  def current_user
    Current.user
  end

  def block_users
    return unless authenticated?

    redirect_to new_session_path, alert: "Your account has been blocked." if current_user.blocked?
  end

  def forbidden
    head :forbidden
  end

  def pundit_user
    current_user
  end

  def turbo_stream_template_exists?
    lookup_context.exists?(action_name, _prefixes, false, [], formats: [:turbo_stream])
  end
end
