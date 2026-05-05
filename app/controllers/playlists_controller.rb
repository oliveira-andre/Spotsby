# frozen_string_literal: true

# PlaylistsController
class PlaylistsController < ApplicationController
  before_action :load_playlist, only: %i[show song_picker update_position]

  def show; end

  def update_position
    return head :forbidden if @playlist.position.to_i.zero?

    position = params[:position].to_i
    return head :unprocessable_content if position < 1

    @playlist.insert_at(position)
    head :ok
  end

  def create_options
    respond_to do |format|
      format.turbo_stream { render :create_options }
    end
  end

  def new
    @playlist = current_user.playlists.new
  end

  def create
    @playlist = current_user.playlists.new(playlist_params)

    if @playlist.save
      redirect_to playlist_path(@playlist, picker: 1)
    else
      flash.now[:alert] = @playlist.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def song_picker
    query = params[:q].to_s.strip

    @songs =
      if query.present?
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
        Song.where("name ILIKE ?", pattern)
            .with_attached_image
            .includes(:authors, :album)
            .limit(30)
      else
        songs_from_user_other_playlists
      end

    @playlist_song_ids = @playlist.song_ids.to_set

    respond_to do |format|
      format.turbo_stream { render :song_picker }
    end
  end

  private

  def load_playlist
    @playlist = current_user.playlists
                            .with_attached_image
                            .friendly
                            .find(params[:id])
    @playlist_songs = @playlist.playlist_songs
                               .includes(song: [ :authors, :album, { image_attachment: :blob } ])
                               .ordered
  end

  def playlist_params
    params.require(:playlist).permit(:name, :status, :image)
  end

  def songs_from_user_other_playlists
    Song.joins(:playlist_songs)
        .where(playlist_songs: { playlist_id: current_user.playlist_ids - [ @playlist.id ] })
        .with_attached_image
        .includes(:authors, :album)
        .distinct
        .limit(30)
  end
end
