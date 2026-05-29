require "open3"

class AudioFragmentClipper
  class Error < StandardError; end

  def self.call(blob:, duration: 15)
    new(blob: blob, duration: duration).call
  end

  def initialize(blob:, duration: 15)
    @blob = blob
    @duration = duration
  end

  def call
    input = Tempfile.new([ "fragment-input", input_extension ], binmode: true)
    output = Tempfile.new([ "fragment-output", ".mp3" ], binmode: true)

    download_blob_to(input)
    run_ffmpeg(input.path, output.path)
    output.rewind
    output
  ensure
    input&.close
    input&.unlink
  end

  private

  def download_blob_to(file)
    @blob.download { |chunk| file.write(chunk) }
    file.flush
  end

  def run_ffmpeg(input_path, output_path)
    cmd = [
      "ffmpeg", "-y", "-i", input_path,
      "-t", @duration.to_s,
      "-acodec", "libmp3lame", "-b:a", "128k",
      "-vn",
      output_path
    ]
    _stdout, stderr, status = Open3.capture3(*cmd)
    raise Error, "ffmpeg failed: #{stderr.lines.last(5).join}" unless status.success?
  end

  def input_extension
    case @blob.content_type
    when "audio/mpeg" then ".mp3"
    when "audio/mp4" then ".m4a"
    when "audio/ogg" then ".ogg"
    when "audio/vnd.wave", "audio/wav" then ".wav"
    else ".bin"
    end
  end
end
