class PlaylistCloning
  def initialize(user:, source:)
    @user = user
    @source = source
  end

  def call
    ActiveRecord::Base.transaction do
      clone = @user.playlists.create!(
        name: unique_name_for(@source.name),
        status: :private
      )

      copy_image(clone)

      @source.playlist_songs.ordered.each do |ps|
        clone.playlist_songs.create!(
          song_id: ps.song_id,
          position: ps.position,
          added_at: Time.current
        )
      end

      clone
    end
  end

  private

  def copy_image(clone)
    return unless @source.image.attached?

    clone.image.attach(
      io: StringIO.new(@source.image.download),
      filename: @source.image.filename.to_s,
      content_type: @source.image.content_type
    )
  end

  def unique_name_for(name)
    candidate = name
    suffix = 1
    while @user.playlists.exists?(name: candidate)
      suffix += 1
      candidate = suffix == 2 ? "#{name} (Copy)" : "#{name} (Copy #{suffix - 1})"
    end
    candidate
  end
end
