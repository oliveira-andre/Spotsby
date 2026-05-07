module Admin
  class AlbumSongsController < AdminController
    before_action :load_author
    before_action :load_album

    def new
      @song = @album.songs.build
    end

    def create
      attrs = song_params
      attrs[:category_id] = @album.category_id if attrs[:category_id].blank?
      @song = @album.songs.build(attrs)

      if @song.save
        @song.authors << @author unless @song.authors.include?(@author)
        respond_to do |format|
          format.turbo_stream
        end
      else
        render turbo_stream: turbo_stream.update(
          "author-wizard-step",
          partial: "admin/authors/wizard_song",
          locals: { author: @author, album: @album, song: @song }
        ), status: :unprocessable_content
      end
    end

    private

    def load_author
      @author = Author.with_attached_image.friendly.find(params[:author_id])
    end

    def load_album
      @album = @author.albums.with_attached_image.friendly.find(params[:album_id])
    end

    def song_params
      params.require(:song).permit(
        :name, :category_id, :lyrics, :duration_ms, :age,
        :monthly_listeners, :popular, :image, :audio
      )
    end
  end
end
