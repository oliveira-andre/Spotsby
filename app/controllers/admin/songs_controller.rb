module Admin
  class SongsController < AdminController
    before_action :load_song, only: %i[edit update destroy update_position]

    def index
      matching_album_ids = Album.joins(:songs)

      if params[:q].present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        matching_album_ids = matching_album_ids.left_joins(:author).where(
          "songs.name ILIKE :q OR albums.name ILIKE :q OR authors.name ILIKE :q",
          q: like
        )
      end

      matching_album_ids = matching_album_ids.where(author_id: params[:author_id]) if params[:author_id].present?
      matching_album_ids = matching_album_ids.where(id: params[:album_id]) if params[:album_id].present?

      album_scope = Album.with_attached_image
                         .includes(:author)
                         .where(id: matching_album_ids.select("albums.id").distinct)
                         .order("LOWER(albums.name)", "albums.id") # id tiebreaker: names collide

      @pagy, @albums = pagy(album_scope, limit: DEFAULT_PER_PAGE)

      songs_scope = Song.with_attached_image
                        .where(album_id: @albums.map(&:id))
                        .order(:position)

      if params[:q].present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        songs_scope = songs_scope.where(
          "songs.name ILIKE :q OR album_id IN (SELECT id FROM albums WHERE name ILIKE :q)" \
          " OR album_id IN (SELECT albums.id FROM albums JOIN authors ON authors.id = albums.author_id WHERE authors.name ILIKE :q)",
          q: like
        )
      end

      @songs_by_album = songs_scope.group_by(&:album_id)

      @authors_for_filter = Rails.cache.fetch([ "admin/authors_for_filter", Author.count, Author.maximum(:updated_at)&.to_i ]) do
        Author.order(:name).pluck(:name, :id)
      end
      @albums_for_filter = Rails.cache.fetch([ "admin/albums_for_filter", Album.count, Album.maximum(:updated_at)&.to_i ]) do
        Album.includes(:author).order("LOWER(albums.name)").to_a
      end
    end

    def new
      scope = Author.with_attached_image.order(:name, :id)

      if params[:q].present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        scope = scope.where("name ILIKE :q", q: like)
      end

      @pagy, @authors = pagy(scope, limit: DEFAULT_PER_PAGE)
    end

    def select_author
      @author = Author.with_attached_image.find(params[:author_id])
      @albums = @author.albums.with_attached_image.ordered

      respond_to do |format|
        format.turbo_stream
      end
    end

    def select_album
      @author = Author.with_attached_image.find(params[:author_id])
      @album = @author.albums.with_attached_image.find(params[:album_id])
      @song = @album.songs.build

      respond_to do |format|
        format.turbo_stream
      end
    end

    def edit; end

    def update
      attrs = song_params
      new_position = attrs.delete(:position).presence&.to_i
      additional_author_ids = attrs.delete(:additional_author_ids)
      @reordered = false

      if @song.update(attrs)
        if additional_author_ids
          album_author_id = @song.album&.author_id
          @song.author_ids = [ album_author_id, *additional_author_ids ].compact_blank.uniq
        end
        if new_position && new_position != @song.position
          @song.insert_at(new_position)
          @reordered = true
          @album_songs = Song.with_attached_image
                             .where(album_id: @song.album_id)
                             .order(:position)
        end
        respond_to do |format|
          format.turbo_stream
        end
      else
        render turbo_stream: turbo_stream.replace(
          "song-form",
          partial: "admin/songs/form",
          locals: { song: @song }
        ), status: :unprocessable_content
      end
    end

    def destroy
      @song.destroy
      respond_to do |format|
        format.turbo_stream
      end
    end

    def update_position
      position = params[:position].to_i
      return head :unprocessable_content if position < 1

      @song.insert_at(position)
      head :ok
    end

    private

    def load_song
      @song = Song.with_attached_image.friendly.find(params[:id])
    end

    def song_params
      params.require(:song).permit(
        :name, :category_id, :lyrics, :duration_ms, :age,
        :monthly_listeners, :popular, :image, :audio, :position,
        additional_author_ids: []
      )
    end
  end
end
