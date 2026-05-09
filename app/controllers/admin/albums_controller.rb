module Admin
  class AlbumsController < AdminController
    before_action :load_album, only: %i[edit update destroy update_position]

    def index
      author_scope = Author.with_attached_image
                           .joins(:albums)
                           .distinct
                           .order(:name)

      if params[:q].present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        author_scope = author_scope.where("authors.name ILIKE :q OR albums.name ILIKE :q", q: like)
      end

      @pagy, @authors = pagy(author_scope, limit: DEFAULT_PER_PAGE)

      albums_scope = Album.with_attached_image
                          .includes(:category)
                          .where(author_id: @authors.map(&:id))
                          .order(:position)

      if params[:q].present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        albums_scope = albums_scope.where(
          "albums.name ILIKE :q OR author_id IN (SELECT id FROM authors WHERE name ILIKE :q)",
          q: like
        )
      end

      @albums_by_author = albums_scope.group_by(&:author_id)
      @song_counts = Song.where(album_id: albums_scope.map(&:id)).group(:album_id).count
    end

    def new
      @authors = Author.with_attached_image.order(:name)
    end

    def select_author
      @author = Author.with_attached_image.find(params[:author_id])
      @album = @author.albums.build

      respond_to do |format|
        format.turbo_stream
      end
    end

    def edit; end

    def update
      attrs = album_params
      new_position = attrs.delete(:position).presence&.to_i
      @reordered = false

      if @album.update(attrs)
        if new_position && new_position != @album.position
          @album.insert_at(new_position)
          @reordered = true
          @author_albums = Album.with_attached_image
                                .includes(:category)
                                .where(author_id: @album.author_id)
                                .order(:position)
          @song_counts = Song.where(album_id: @author_albums.map(&:id)).group(:album_id).count
        end
        respond_to do |format|
          format.turbo_stream
        end
      else
        render turbo_stream: turbo_stream.replace(
          "album-form",
          partial: "admin/albums/form",
          locals: { album: @album }
        ), status: :unprocessable_content
      end
    end

    def destroy
      @album.destroy
      respond_to do |format|
        format.turbo_stream
      end
    end

    def update_position
      position = params[:position].to_i
      return head :unprocessable_content if position < 1

      @album.insert_at(position)
      head :ok
    end

    private

    def load_album
      @album = Album.with_attached_image.friendly.find(params[:id])
    end

    def album_params
      params.require(:album).permit(:name, :release_date, :category_id, :image, :position)
    end
  end
end
