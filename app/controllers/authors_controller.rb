# frozen_string_literal: true

# AuthorsController
class AuthorsController < ApplicationController
  POPULAR_SONGS_LIMIT = 10

  before_action :load_author, only: %i[show all_songs]

  def show
    @popular_songs = @author.popular_songs
                            .includes(song: [:authors, { image_attachment: :blob }])
                            .limit(POPULAR_SONGS_LIMIT)
                            .map(&:song)

    albums = @author.albums.with_attached_image
                    .includes(songs: [:authors, { image_attachment: :blob }])
    @pagy, @albums = pagy(albums, limit: DEFAULT_PER_PAGE)
  end

  def all_songs
    songs = Song.joins(:album)
                .where(albums: { author_id: @author.id })
                .includes(:authors, :album, image_attachment: :blob)
                .order("albums.position ASC, songs.position ASC")
    @pagy, @songs = pagy(songs, limit: DEFAULT_PER_PAGE)
  end

  private

  def load_author
    @author = Author.with_attached_image.friendly.find(params[:id])
  end
end
