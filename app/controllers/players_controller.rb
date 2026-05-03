# frozen_string_literal: true

# PlayersController
class PlayersController < ApplicationController
  before_action :load_song, only: %i[show]

  def show
    return unless @song && params[:source].present?

    record_queue_entry!(@song, params[:source])
    record_play_history!(@song, params[:source])
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

  def advance(direction:)
    latest = SongQueue.where(user: current_user).recent.first
    current_song = latest&.song
    return redirect_back_or_to(root_path) unless current_song

    next_song, source = resolve_next(current_song, latest.source, direction)
    return redirect_back_or_to(player_path(current_song)) unless next_song

    record_queue_entry!(next_song, source)
    redirect_to player_path(next_song)
  end

  def resolve_next(current_song, current_source, direction)
    case current_source
    when SongQueue::SOURCE_ALBUM
      sibling = album_sibling(current_song, direction)
      return [sibling, SongQueue::SOURCE_ALBUM] if sibling
    when SongQueue::SOURCE_POPULAR
      sibling = popular_sibling(current_song, direction)
      return [sibling, SongQueue::SOURCE_POPULAR] if sibling
    end

    [sample_artist_song(current_song), SongQueue::SOURCE_ARTIST_SHUFFLE]
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

  def record_queue_entry!(song, source)
    return unless current_user
    return unless SongQueue::SOURCES.include?(source.to_s)

    SongQueue.create!(user: current_user, song: song, source: source)
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
