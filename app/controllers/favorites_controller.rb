# frozen_string_literal: true

# FavoritesController
class FavoritesController < ApplicationController
  before_action :load_song,  only: %i[create_song destroy_song playlists_modal add_to_playlist]
  before_action :load_album, only: %i[create_album destroy_album]

  def create_song
    playlist = ensure_saved_songs_playlist
    playlist.songs << @song unless playlist.playlist_songs.exists?(song_id: @song.id)
    current_user.reload
    @saved = true

    respond_to do |format|
      format.turbo_stream { render :song_heart }
    end
  end

  def destroy_song
    PlaylistSong.where(playlist_id: current_user.playlist_ids, song_id: @song.id).destroy_all
    current_user.reload
    @saved = false

    respond_to do |format|
      format.turbo_stream { render :song_heart }
    end
  end

  def playlists_modal
    @playlists = current_user.playlists.where.not(position: 0).ordered

    respond_to do |format|
      format.turbo_stream { render :playlists_modal }
    end
  end

  def add_to_playlist
    @playlist = current_user.playlists.find(params[:playlist_id])

    @playlist.songs << @song unless @playlist.playlist_songs.exists?(song_id: @song.id)
    saved = current_user.saved_songs_playlist
    saved&.playlist_songs&.where(song_id: @song.id)&.destroy_all

    current_user.reload
    @saved = song_in_any_playlist?(@song)

    respond_to do |format|
      format.turbo_stream { render :add_to_playlist }
    end
  end

  def create_album
    playlist = current_user.album_playlist(@album)
    unless playlist
      playlist = current_user.playlists.create!(name: @album.name)
      playlist.image.attach(@album.image.blob) if @album.image.attached?
      @album.songs.each { |song| playlist.songs << song }
    end
    current_user.reload
    @saved = true

    respond_to do |format|
      format.turbo_stream { render :album_heart }
    end
  end

  def destroy_album
    current_user.album_playlist(@album)&.destroy
    current_user.reload
    @saved = false

    respond_to do |format|
      format.turbo_stream { render :album_heart }
    end
  end

  private

  def load_song
    @song = Song.friendly.find(params[:id])
    @button_class = params[:button_class] || "song-heart"
    @size = (params[:size] || 20).to_i
  end

  def load_album
    @album = Album.friendly.find(params[:id])
    @button_class = params[:button_class] || "album-show__icon-btn"
    @size = (params[:size] || 24).to_i
  end

  def ensure_saved_songs_playlist
    current_user.saved_songs_playlist ||
      current_user.playlists.create!(name: "Saved Songs", status: :private, position: 0)
  end

  def song_in_any_playlist?(song)
    PlaylistSong.where(playlist_id: current_user.playlist_ids, song_id: song.id).exists?
  end
end
