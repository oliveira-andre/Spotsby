module ApplicationHelper
  # Admin add/edit forms open in a Turbo frame overlay on the web. In the app
  # they must be full page visits so the path configuration (`/new$`, `/edit$`)
  # presents them as native modals.
  def admin_form_frame(name)
    hotwire_native_app? ? "_top" : "#{name}-form-modal"
  end

  # The outer frame of those forms: in the app it targets the whole page, so a
  # redirect after saving becomes a native visit (dismiss + refresh) instead of
  # a frame fetch with no matching frame.
  def admin_form_frame_target
    hotwire_native_app? ? "_top" : nil
  end

  def song_saved?(song)
    return false unless current_user

    @_saved_song_ids ||= current_user.saved_song_ids.to_set
    @_saved_song_ids.include?(song.id)
  end

  def album_saved?(album)
    return false unless current_user

    @_saved_album_names ||= current_user.saved_album_names.to_set
    @_saved_album_names.include?(album.name)
  end

  # Force a redirect-mode URL for an Active Storage blob, bypassing the global
  # proxy-mode default. Use for audio (large, range-streamed) so storage
  # serves bytes directly instead of tying up Rails workers.
  def redirect_blob_url(blob_or_attached)
    blob = blob_or_attached.respond_to?(:blob) ? blob_or_attached.blob : blob_or_attached
    return nil unless blob

    rails_service_blob_url(blob.signed_id, blob.filename)
  end

  # Everything a player needs to show and play a song. Rendered into the
  # `song_event` and big player partials and returned as JSON to the native
  # app, so all three always agree on the field list. `song` may be nil.
  def song_payload(song)
    image =
      if song&.image&.attached?
        song.image
      elsif song&.album&.image&.attached?
        song.album.image
      end

    {
      id: song&.id,
      slug: song&.slug,
      name: song&.name,
      authors: song ? song.authors.map(&:name).join(", ") : nil,
      album: song&.album&.name,
      image_url: image ? url_for(image) : nil,
      image_content_type: image&.blob&.content_type,
      audio_url: song&.audio&.attached? ? redirect_blob_url(song.audio) : nil,
      fragment_url: song&.audio_fragment&.attached? ? redirect_blob_url(song.audio_fragment) : nil,
      duration_ms: song&.duration_ms
    }
  end
end
