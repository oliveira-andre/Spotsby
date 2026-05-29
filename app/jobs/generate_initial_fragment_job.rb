class GenerateInitialFragmentJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(song_id)
    song = Song.find_by(id: song_id)
    return unless song
    return unless song.audio.attached?
    return if song.audio_fragment.attached?

    tempfile = AudioFragmentClipper.call(blob: song.audio.blob)
    song.audio_fragment.attach(
      io: tempfile,
      filename: "#{song.id}-fragment.mp3",
      content_type: "audio/mpeg"
    )
  ensure
    tempfile&.close
    tempfile&.unlink
  end
end
