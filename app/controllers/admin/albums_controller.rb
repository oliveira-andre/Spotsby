module Admin
  class AlbumsController < AdminController
    before_action :load_album, only: %i[edit update destroy]

    def index
      scope = Album.with_attached_image.includes(:author, :category).order(created_at: :desc)

      if params[:q].present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        scope = scope.where("albums.name ILIKE :q OR authors.name ILIKE :q", q: like).references(:author)
      end

      @pagy, @albums = pagy(scope, limit: DEFAULT_PER_PAGE)
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
      if @album.update(album_params)
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

    private

    def load_album
      @album = Album.with_attached_image.friendly.find(params[:id])
    end

    def album_params
      params.require(:album).permit(:name, :release_date, :category_id, :image)
    end
  end
end
