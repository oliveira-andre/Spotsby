# frozen_string_literal: true

# Admin add/edit forms live in an overlay on the web and in a native modal in
# the app. After a save that should close the form, the web gets Turbo Streams
# that patch the list and empty the overlay; the app instead needs the modal
# dismissed and the list underneath reloaded, which `refresh_or_redirect_to`
# asks for through Turbo's native navigation route.
module Admin::ModalResponses
  extend ActiveSupport::Concern

  private

  def saved_in_modal(list_path)
    if hotwire_native_app?
      refresh_or_redirect_to(list_path)
    else
      respond_to do |format|
        format.turbo_stream
      end
    end
  end
end
