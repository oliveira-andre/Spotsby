module Admin
  class SongsController < AdminController
    SORTS = %w[newest name album author].freeze

    before_action :load_song, only: %i[edit update destroy update_position]

    def index
      scope = Song.with_attached_image.includes(album: :author)

      needs_join = params[:q].present? || %w[album author].include?(params[:sort])
      scope = scope.left_joins(album: :author) if needs_join

      if params[:q].present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        scope = scope.where(
          "songs.name ILIKE :q OR albums.name ILIKE :q OR authors.name ILIKE :q",
          q: like
        ).distinct
      end

      if params[:author_id].present?
        scope = scope.where(album_id: Album.where(author_id: params[:author_id]))
      end

      scope = scope.where(album_id: params[:album_id]) if params[:album_id].present?

      scope = sort_scope(scope, params[:sort], params[:dir])

      @pagy, @songs = pagy(scope, limit: DEFAULT_PER_PAGE)

      @authors_for_filter = Author.order(:name).pluck(:name, :id)
      @albums_for_filter = Album.includes(:author).order("LOWER(albums.name)").to_a
    end

    def new
      @authors = Author.with_attached_image.order(:name)
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
      if @song.update(song_params)
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

    def sort_scope(scope, sort, dir)
      direction = (dir == "asc") ? "asc" : "desc"

      case sort
      when "name"
        scope.reorder("songs.name #{direction}")
      when "album"
        scope.reorder("albums.name #{direction}, songs.name asc")
      when "author"
        scope.reorder("authors.name #{direction}, albums.name asc, songs.name asc")
      else
        scope.reorder("songs.created_at desc")
      end
    end

    def load_song
      @song = Song.with_attached_image.friendly.find(params[:id])
    end

    def song_params
      params.require(:song).permit(
        :name, :category_id, :lyrics, :duration_ms, :age,
        :monthly_listeners, :popular, :image, :audio
      )
    end
  end
end
