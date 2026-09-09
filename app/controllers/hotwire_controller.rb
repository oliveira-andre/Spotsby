class HotwireController < ApplicationController
  skip_before_action :require_authentication

  def refresh; end
end