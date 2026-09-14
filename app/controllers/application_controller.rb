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
      if hotwire_native_app? && request.get?
        # Turbo submits `data-turbo-stream` links as hidden GET forms and
        # fetches them itself, so the app never gets a visit proposal. A
        # page-content stream would then swap the page inside the current
        # native screen: no navigation bar, and the mini player stays.
        # Answering with the full page makes Turbo propose a visit carrying
        # this response, and the app pushes a proper screen for it.
        render action_name, formats: :html
      else
        body = render_to_string(action_name, layout: false)
        render turbo_stream: turbo_stream.update("page-content", body)
      end
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
    return unless current_user.blocked?
    return head :forbidden if request.format.json?

    redirect_to new_session_path, alert: "Your account has been blocked."
  end

  def forbidden
    head :forbidden
  end

  def pundit_user
    current_user
  end

  def turbo_stream_template_exists?
    lookup_context.exists?(action_name, _prefixes, false, [], formats: [ :turbo_stream ])
  end
end
