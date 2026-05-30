module ApplicationHelper
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
end
