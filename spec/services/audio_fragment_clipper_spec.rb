require 'rails_helper'

RSpec.describe AudioFragmentClipper do
  let(:fixture_path) { Rails.root.join('spec/fixtures/files/sample.mp3') }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(fixture_path, 'rb'),
      filename: 'sample.mp3',
      content_type: 'audio/mpeg'
    )
  end

  describe '.call' do
    it 'returns a Tempfile with valid MP3 data shorter than the source' do
      output = described_class.call(blob: blob, duration: 5)

      expect(output).to be_a(Tempfile)
      expect(File.size(output.path)).to be > 0
      expect(File.size(output.path)).to be < File.size(fixture_path)

      # MP3s start with either ID3 ("ID3") or a frame sync (0xFF 0xFB/0xFA/etc).
      header = File.binread(output.path, 3)
      expect(header.start_with?('ID3') || header.bytes.first == 0xFF).to be(true)
    ensure
      output&.close
      output&.unlink
    end

    it 'raises Error on an unusable blob' do
      bad = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('not audio data'),
        filename: 'bad.mp3',
        content_type: 'audio/mpeg'
      )
      expect { described_class.call(blob: bad) }.to raise_error(AudioFragmentClipper::Error)
    end
  end
end
