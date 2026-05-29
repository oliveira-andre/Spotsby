namespace :fragments do
  desc "Enqueue GenerateInitialFragmentJob for every Song with audio attached and no fragment yet"
  task backfill: :environment do
    scope = Song.with_attached_audio.where.missing(:audio_fragment_attachment)
    total = 0
    scope.find_each do |song|
      next unless song.audio.attached?

      GenerateInitialFragmentJob.perform_later(song.id)
      total += 1
    end
    puts "Enqueued GenerateInitialFragmentJob for #{total} songs."
  end
end
