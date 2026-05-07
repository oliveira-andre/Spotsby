module Admin
  class PlaylistSongsController < AdminController
    before_action :load_playlist
    before_action :load_song, only: %i[create destroy]

    def picker
      query = params[:q].to_s.strip
      base = Song.with_attached_image.includes(album: :author)

      @songs = if query.present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
        base.left_joins(album: :author)
            .where("songs.name ILIKE :q OR albums.name ILIKE :q OR authors.name ILIKE :q", q: like)
            .distinct
            .limit(30)
      else
        base.order(created_at: :desc).limit(30)
      end

      @existing_song_ids = @playlist.song_ids.to_set

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def create
      @playlist.songs << @song unless @playlist.playlist_songs.exists?(song_id: @song.id)
      respond_to do |format|
        format.turbo_stream
      end
    end

    def destroy
      @playlist.playlist_songs.where(song_id: @song.id).destroy_all
      respond_to do |format|
        format.turbo_stream
      end
    end

    private

    def load_playlist
      @playlist = Playlist.friendly.find(params[:playlist_id])
    end

    def load_song
      song_id = params[:song_id].presence || params[:id]
      @song = Song.with_attached_image.includes(album: :author).find(song_id)
    end
  end
end
