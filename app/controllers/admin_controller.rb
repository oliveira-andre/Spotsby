class AdminController < ApplicationController
  class Unauthorized < StandardError; end

  layout "admin"

  rescue_from Unauthorized, with: :unauthorized

  before_action :require_admin

  private

  def require_admin
    raise Unauthorized unless current_user&.admin?
  end

  def unauthorized
    head :unauthorized
  end
end
