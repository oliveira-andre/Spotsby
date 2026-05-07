module Admin
  class AlbumsController < AdminController
    before_action :load_album

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
