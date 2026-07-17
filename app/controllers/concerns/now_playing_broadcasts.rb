# frozen_string_literal: true

# Shared helpers for pointing playback at a device and telling every other
# device about it. "Active" = the single session that owns audio output.
module NowPlayingBroadcasts
  extend ActiveSupport::Concern

  private

  # Make the current device (Current.session) the active playback device and
  # broadcast so any previously-active device goes passive. Returns true when the
  # active device actually changed.
  def claim_active_session!
    return false unless current_user && Current.session
    return false if current_user.active_session_id == Current.session.id

    current_user.update!(active_session_id: Current.session.id)
    broadcast_active_device
    true
  end

  def broadcast_active_device
    Turbo::StreamsChannel.broadcast_replace_to(
      current_user, :now_playing,
      target: "now-playing-active-device",
      partial: "shared/now_playing_active_device",
      locals: { user: current_user }
    )
  end
end
