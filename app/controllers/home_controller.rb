# frozen_string_literal: true

# HomeController
class HomeController < ApplicationController
  before_action :load_profile_stats, only: :profile

  def index
    load_home_feed
  end

  def profile; end

  def all
    load_home_feed
  end

  def search
    @categories = Rails.cache.fetch("categories") do
      Category.with_attached_image.ordered
    end

    @play_histories = current_user.play_histories
                                  .from_search
                                  .includes(song: [ :authors, :album, { image_attachment: :blob } ])
                                  .recent
                                  .limit(20)
  end

  def search_results
    query = params[:q].to_s.strip

    if query.blank?
      @songs = Song.none
      @albums = Album.none
      @authors = Author.none
      @playlists = Playlist.none
    else
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"

      @songs = Song.where("name ILIKE :p OR lyrics ILIKE :p", p: pattern)
                   .with_attached_image
                   .includes(:album, :authors)
                   .limit(20)

      @albums = Album.where("name ILIKE ?", pattern)
                     .with_attached_image
                     .includes(:author)
                     .limit(20)

      @authors = Author.where("name ILIKE ?", pattern)
                       .with_attached_image
                       .limit(20)

      @playlists = Playlist.public_status
                           .where("name ILIKE ?", pattern)
                           .with_attached_image
                           .includes(:user, playlist_songs: { song: { image_attachment: :blob } })
                           .limit(10)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "search_results",
          partial: "home/search_results"
        )
      end
    end
  end

  def library
    @playlists = current_user.playlists
                             .with_attached_image
                             .with_songs_count
                             .ordered
  end

  def manage; end

  def recent_albums
    @recent_albums = recent_distinct_from_queue(:album, limit: 30)
  end

  def recent_artists
    @recent_artists = recent_distinct_from_queue(:authors, limit: 30)
  end

  private

  def load_profile_stats
    month_start = Time.current.beginning_of_month

    @songs_played_this_month = current_user.play_histories
                                            .where(created_at: month_start..)
                                            .count

    @playlists_count = current_user.playlists.where.not(position: 0).count

    saved = current_user.saved_songs_playlist
    @saved_songs_count = saved ? saved.playlist_songs.count : 0

    @minutes_listened_this_month = current_user.play_histories
                                                .joins(:song)
                                                .where(created_at: month_start..)
                                                .sum("songs.duration_ms")
                                                .to_i / 60_000

    @top_artist = Author.with_attached_image
                        .joins(songs: :play_histories)
                        .where(play_histories: { user_id: current_user.id, created_at: month_start.. })
                        .group("authors.id")
                        .order(Arel.sql("COUNT(play_histories.id) DESC"))
                        .first

    author_ids = current_user.authors.ids
    @owned_albums_count = author_ids.any? ? Album.where(author_id: author_ids).count : 0
    @owned_songs_count  = author_ids.any? ? Song.joins(:song_authors).where(song_authors: { author_id: author_ids }).distinct.count : 0
  end

  def load_home_feed
    queue_includes = {
      song: [ :authors, { album: [ :author, { image_attachment: :blob } ] }, { image_attachment: :blob } ]
    }

    history_pool = current_user.song_queues
                               .recent
                               .includes(queue_includes)
                               .limit(50)

    @recent_tiles = build_recent_tiles(history_pool, limit: 8)

    seen_songs = {}
    seen_artists = {}

    history_pool.each do |entry|
      song = entry.song
      next unless song

      seen_songs[song.id] ||= song
      song.authors.each { |a| seen_artists[a.id] ||= a }
    end

    @jump_back_songs = seen_songs.values.first(10)
    @recent_artists  = seen_artists.values.first(12)
  end

  def build_recent_tiles(entries, limit:)
    album_counts = Hash.new(0)
    entries.each do |entry|
      album_id = entry.song&.album_id
      album_counts[album_id] += 1 if album_id
    end

    tiles = []
    seen_albums = Set.new
    seen_artists = Set.new
    seen_songs = Set.new

    entries.each do |entry|
      song = entry.song
      next unless song
      album = song.album

      if album && album_counts[album.id] > 1
        next if seen_albums.include?(album.id)
        seen_albums << album.id
        tiles << { type: :album, record: album }
      else
        case entry.source
        when SongQueue::SOURCE_POPULAR
          author = song.authors.first
          next unless author
          next if seen_artists.include?(author.id)
          seen_artists << author.id
          tiles << { type: :artist, record: author }
        when SongQueue::SOURCE_ALBUM
          next unless album
          next if seen_albums.include?(album.id)
          seen_albums << album.id
          tiles << { type: :album, record: album }
        else
          next if seen_songs.include?(song.id)
          seen_songs << song.id
          tiles << { type: :song, record: song }
        end
      end

      break if tiles.size >= limit
    end

    tiles
  end

  def recent_distinct_from_queue(kind, limit:)
    pool = current_user.song_queues
                       .recent
                       .includes(song: [ :authors, { album: [ :author, { image_attachment: :blob } ] }, { image_attachment: :blob } ])
                       .limit(200)

    seen = {}
    pool.each do |entry|
      song = entry.song
      next unless song

      case kind
      when :album
        album = song.album
        next unless album
        seen[album.id] ||= album
      when :authors
        song.authors.each { |a| seen[a.id] ||= a }
      end

      break if seen.size >= limit
    end

    seen.values.first(limit)
  end
end
