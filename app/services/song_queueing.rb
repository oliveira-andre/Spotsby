class SongQueueing
  def initialize(user)
    @user = user
  end

  def enqueue(song)
    user_custom_scope.destroy_all unless in_custom_queue?
    @user.song_queues.create!(song: song, source: SongQueue::SOURCE_USER_CUSTOM)
    prune
  end

  private

  def in_custom_queue?
    @user.play_histories.recent.first&.source == SongQueue::SOURCE_USER_CUSTOM
  end

  def user_custom_scope
    @user.song_queues.where(source: SongQueue::SOURCE_USER_CUSTOM)
  end

  def prune
    cap = SongQueue::MAX_PER_USER_BY_SOURCE
    keep_ids = user_custom_scope.reorder(created_at: :desc).limit(cap).pluck(:id)
    user_custom_scope.where.not(id: keep_ids).delete_all
  end
end
