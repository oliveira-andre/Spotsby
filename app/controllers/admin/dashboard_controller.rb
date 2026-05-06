module Admin
  class DashboardController < AdminController
    LATEST_LIMIT = 5

    def index
      @stats = {
        users: User.count,
        categories: Category.count,
        authors: Author.count,
        albums: Album.count,
        songs: Song.count,
        playlists: Playlist.count
      }

      @latest_users   = User.with_attached_avatar.order(created_at: :desc).limit(LATEST_LIMIT)
      @latest_authors = Author.with_attached_image.order(created_at: :desc).limit(LATEST_LIMIT)
      @latest_albums  = Album.with_attached_image.includes(:author).order(created_at: :desc).limit(LATEST_LIMIT)
      @latest_songs   = Song.with_attached_image.includes(:authors, :album).order(created_at: :desc).limit(LATEST_LIMIT)
    end
  end
end
