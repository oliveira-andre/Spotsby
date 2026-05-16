class NowPlayingChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
    session = current_session
    return reject unless session

    session.update!(last_seen_at: Time.current)
    auto_activate_if_only_device(session)
  end

  def heartbeat
    current_session&.update!(last_seen_at: Time.current)
  end

  private

  def current_session
    @current_session ||= Session.find_by(id: connection.cookies.signed[:session_id])
  end

  def auto_activate_if_only_device(session)
    others = current_user.sessions.recently_active.where.not(id: session.id).exists?
    current_user.update!(active_session_id: session.id) unless others
  end
end
