# frozen_string_literal: true

# AuthorsController
class AuthorsController < ApplicationController
  POPULAR_SONGS_LIMIT = 10

  before_action :load_author, only: %i[show all_songs random_song]

  def show
    @popular_entries = @author.popular_songs
                              .includes(song: [ :authors, { image_attachment: :blob } ])
                              .limit(POPULAR_SONGS_LIMIT)
                              .to_a

    albums = @author.albums.with_attached_image
                    .includes(songs: [ :authors, { image_attachment: :blob } ])
    @pagy, @albums = pagy(albums, limit: DEFAULT_PER_PAGE)
  end

  def all_songs
    songs = Song.joins(:album)
                .where(albums: { author_id: @author.id })
                .includes(:authors, :album, image_attachment: :blob)
                .order("albums.position ASC, songs.position ASC")
    @pagy, @songs = pagy(songs, limit: DEFAULT_PER_PAGE)
  end

  def random_song
    song = @author.top_songs.limit(POPULAR_SONGS_LIMIT).sample
    return redirect_to author_path(@author) unless song

    redirect_to player_path(song, source: SongQueue::SOURCE_POPULAR)
  end

  private

  def load_author
    @author = Author.with_attached_image.friendly.find(params[:id])
  end
end
