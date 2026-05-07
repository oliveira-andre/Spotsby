module Admin
  class AuthorAlbumsController < AdminController
    before_action :load_author

    def new
      @album = @author.albums.build
    end

    def create
      @album = @author.albums.build(album_params)

      if @album.save
        respond_to do |format|
          format.turbo_stream
        end
      else
        render turbo_stream: turbo_stream.update(
          "wizard-step",
          partial: "admin/authors/wizard_album",
          locals: { author: @author, album: @album }
        ), status: :unprocessable_content
      end
    end

    private

    def load_author
      @author = Author.with_attached_image.friendly.find(params[:author_id])
    end

    def album_params
      params.require(:album).permit(:name, :release_date, :category_id, :image)
    end
  end
end
