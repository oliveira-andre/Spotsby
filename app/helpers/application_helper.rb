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
end
