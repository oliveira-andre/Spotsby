module Admin
  class PlaylistsController < AdminController
    before_action :load_playlist, only: %i[edit update destroy]

    def index
      scope = Playlist.with_attached_image.includes(:user).order(updated_at: :desc, id: :desc)

      if params[:q].present?
        like = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        scope = scope.where("playlists.name ILIKE ?", like)
      end

      @pagy, @playlists = pagy(scope, limit: DEFAULT_PER_PAGE)
      @song_counts = PlaylistSong.where(playlist_id: @playlists.map(&:id)).group(:playlist_id).count
    end

    def new
      @playlist = Playlist.new
      @users = User.order(:email_address).pluck(:email_address, :id)
    end

    def create
      @playlist = Playlist.new(playlist_params)

      if @playlist.save
        respond_to do |format|
          format.turbo_stream
        end
      else
        @users = User.order(:email_address).pluck(:email_address, :id)
        render turbo_stream: turbo_stream.update(
          "wizard-step",
          partial: "admin/playlists/wizard_playlist",
          locals: { playlist: @playlist, users: @users }
        ), status: :unprocessable_content
      end
    end

    def edit
      @users = User.order(:email_address).pluck(:email_address, :id)
    end

    def update
      if @playlist.update(playlist_params)
        respond_to do |format|
          format.turbo_stream
        end
      else
        @users = User.order(:email_address).pluck(:email_address, :id)
        render turbo_stream: turbo_stream.replace(
          "playlist-form",
          partial: "admin/playlists/form",
          locals: { playlist: @playlist, users: @users }
        ), status: :unprocessable_content
      end
    end

    def destroy
      @playlist.destroy
      respond_to do |format|
        format.turbo_stream
      end
    end

    private

    def load_playlist
      @playlist = Playlist.with_attached_image.friendly.find(params[:id])
    end

    def playlist_params
      params.require(:playlist).permit(:name, :status, :image, :user_id)
    end
  end
end
