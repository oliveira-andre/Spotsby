# frozen_string_literal: true

# PlayersController
class PlayersController < ApplicationController
  before_action :load_song, only: %i[show]

  def show
    return unless @song

    source = params[:source].presence
    source_id = source_id_for(source)
    record_queue_entry!(@song, source, source_id)
    record_play_history!(@song, source)
  end

  def next
    advance(direction: :next)
  end

  def previous
    advance(direction: :previous)
  end

  private

  def load_song
    @song = nil
    return unless params[:song_id].present? || params[:id].present?

    slug = params[:song_id].presence || params[:id]
    @song = Song.friendly.find(slug)
  rescue ActiveRecord::RecordNotFound
    @song = nil
  end

  def source_id_for(source)
    case source
    when SongQueue::SOURCE_PLAYLIST then params[:playlist_id].presence
    end
  end

  def advance(direction:)
    latest = SongQueue.where(user: current_user).recent.first
    current_song = latest&.song
    return redirect_back_or_to(root_path) unless current_song

    next_song, source, source_id = resolve_next(current_song, latest.source, latest.source_id, direction)
    return redirect_back_or_to(player_path(current_song)) unless next_song

    record_queue_entry!(next_song, source, source_id)
    redirect_to player_path(next_song)
  end

  def resolve_next(current_song, current_source, current_source_id, direction)
    case current_source
    when SongQueue::SOURCE_PLAYLIST
      sibling = playlist_sibling(current_song, current_source_id, direction)
      return [ sibling, SongQueue::SOURCE_PLAYLIST, current_source_id ] if sibling
    when SongQueue::SOURCE_ALBUM
      sibling = album_sibling(current_song, direction)
      return [ sibling, SongQueue::SOURCE_ALBUM, nil ] if sibling
    when SongQueue::SOURCE_POPULAR
      sibling = popular_sibling(current_song, direction)
      return [ sibling, SongQueue::SOURCE_POPULAR, nil ] if sibling
    end

    [ sample_artist_song(current_song), SongQueue::SOURCE_ARTIST_SHUFFLE, nil ]
  end

  def playlist_sibling(song, playlist_id, direction)
    return nil unless playlist_id

    playlist = current_user.playlists.find_by(id: playlist_id)
    return nil unless playlist

    song_ids = playlist.playlist_songs.ordered.pluck(:song_id)
    return nil if song_ids.empty?

    index = song_ids.index(song.id)
    return Song.find_by(id: song_ids.first) if index.nil?

    offset = direction == :next ? 1 : -1
    target_index = (index + offset) % song_ids.size
    Song.find_by(id: song_ids[target_index])
  end

  def album_sibling(song, direction)
    offset = direction == :next ? 1 : -1
    target_position = song.position.to_i + offset
    return nil if target_position < 1

    Song.where(album_id: song.album_id, position: target_position).first
  end

  def popular_sibling(song, direction)
    author_id = song.album&.author_id
    return nil unless author_id

    current_entry = PopularSong.find_by(author_id: author_id, song_id: song.id)
    return nil unless current_entry

    offset = direction == :next ? 1 : -1
    target_position = current_entry.position.to_i + offset
    return nil if target_position < 1

    PopularSong.where(author_id: author_id, position: target_position).first&.song
  end

  def sample_artist_song(current_song)
    return nil unless current_song.album&.author_id

    Song.joins(:album)
        .where(albums: { author_id: current_song.album.author_id })
        .where.not(id: current_song.id)
        .order(Arel.sql("RANDOM()"))
        .first
  end

  def record_queue_entry!(song, source, source_id = nil)
    return unless current_user

    effective_source = SongQueue::SOURCES.include?(source.to_s) ? source : SongQueue::SOURCE_DEFAULT
    SongQueue.create!(
      user: current_user,
      song: song,
      source: effective_source,
      source_id: source_id
    )
    prune_song_queues!(effective_source)
  end

  def prune_song_queues!(source)
    cap = SongQueue.cap_for(source)
    scope = current_user.song_queues.where(source: source)
    keep_ids = scope.recent.limit(cap).pluck(:id)
    scope.where.not(id: keep_ids).delete_all
  end

  def record_play_history!(song, source)
    return unless current_user

    current_user.play_histories.create!(song: song, source: source, played_at: Time.current)
    prune_play_histories!(source)
  end

  def prune_play_histories!(source)
    cap = PlayHistory.cap_for(source)
    scope = current_user.play_histories
    scope = source.present? ? scope.where(source: source) : scope.where(source: nil)
    keep_ids = scope.recent.limit(cap).pluck(:id)
    scope.where.not(id: keep_ids).delete_all
  end
end
