module Admin
  class SongsController < AdminController
    before_action :load_song, only: %i[edit update destroy update_position]

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
