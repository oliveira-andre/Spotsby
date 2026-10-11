require "rails_helper"

# Each check is read through #call, so a failing service must come back as `false`,
# never as an exception. Failures are made by breaking the thing a check calls, not by
# stubbing the check: an any_instance stub on a check would leak a public
# `__<name>_without_any_instance__` method into the answer.
RSpec.describe HealthCheckService do
  subject(:service) { described_class.new }

  before do
    # The app check requests the project's own /up. Never hit a real server in specs.
    allow(HTTParty).to receive(:get).and_return(double(success?: true))
  end

  it "answers app first, then every check by name, with booleans only" do
    result = service.call

    expect(result.keys).to eq(%i[app cable cache database ffmpeg jobs storage])
    expect(result.values).to all(be(true).or(be(false)))
  end

  describe "app" do
    it "is on when /up answers with success" do
      expect(service.call[:app]).to be(true)
      expect(HTTParty).to have_received(:get).with(a_string_ending_with("/up"), timeout: described_class::TIMEOUT)
    end

    it "is off when /up fails or times out" do
      allow(HTTParty).to receive(:get).and_return(double(success?: false))
      expect(service.call[:app]).to be(false)

      allow(HTTParty).to receive(:get).and_raise(Net::OpenTimeout)
      expect(service.call[:app]).to be(false)
    end
  end

  describe "cable" do
    it "is on outside Solid Cable, where the adapter runs in this process" do
      expect(service.call[:cable]).to be(true)
    end

    context "on Solid Cable" do
      before { allow(service).to receive(:solid_cable?).and_return(true) }

      it "is on when its database answers" do
        expect(service.call[:cable]).to be(true)
      end

      it "is off when its database is unreachable" do
        allow(SolidCable::Record).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)
        expect(service.call[:cable]).to be(false)
      end
    end
  end

  describe "cache" do
    it "is on when the cache stores and returns a value, and cleans up after itself" do
      store = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(store)
      expect(store).to receive(:delete).with(a_string_starting_with("services_health_check:")).and_call_original

      expect(service.call[:cache]).to be(true)
    end

    it "is off when the cache loses the value" do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::NullStore.new)
      expect(service.call[:cache]).to be(false)
    end
  end

  describe "database" do
    it "is on when the primary database answers" do
      expect(service.call[:database]).to be(true)
    end

    it "is off when the query fails" do
      allow(ActiveRecord::Base.connection).to receive(:select_value).and_raise(ActiveRecord::ConnectionNotEstablished)
      expect(service.call[:database]).to be(false)
    end
  end

  describe "ffmpeg" do
    it "is on when ffmpeg runs" do
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture3).with("ffmpeg", "-version").and_return([ "ffmpeg version 8", "", status ])

      expect(service.call[:ffmpeg]).to be(true)
    end

    it "is off when ffmpeg is missing" do
      allow(Open3).to receive(:capture3).with("ffmpeg", "-version").and_raise(Errno::ENOENT)
      expect(service.call[:ffmpeg]).to be(false)
    end
  end

  describe "jobs" do
    it "is on outside Solid Queue, where the adapter runs in this process" do
      expect(service.call[:jobs]).to be(true)
    end

    context "on Solid Queue" do
      before do
        allow(service).to receive(:solid_queue?).and_return(true)
        allow(service).to receive(:live_queue_process_kinds).and_return(%w[Supervisor(puma) Worker Dispatcher])
        allow(service).to receive(:oldest_ready_job_at).and_return(nil)
      end

      it "is on with a live worker and dispatcher and nothing waiting" do
        expect(service.call[:jobs]).to be(true)
      end

      it "is on when the oldest ready job is recent" do
        allow(service).to receive(:oldest_ready_job_at).and_return(1.minute.ago)
        expect(service.call[:jobs]).to be(true)
      end

      it "is off when no worker is alive" do
        allow(service).to receive(:live_queue_process_kinds).and_return(%w[Supervisor(puma) Dispatcher])
        expect(service.call[:jobs]).to be(false)
      end

      it "is off when no dispatcher is alive" do
        allow(service).to receive(:live_queue_process_kinds).and_return(%w[Supervisor(puma) Worker])
        expect(service.call[:jobs]).to be(false)
      end

      it "is off when a job has waited longer than the limit" do
        allow(service).to receive(:oldest_ready_job_at).and_return(described_class::QUEUE_LATENCY_LIMIT.ago - 1.minute)
        expect(service.call[:jobs]).to be(false)
      end

      it "is off when the queue database is unreachable" do
        allow(service).to receive(:live_queue_process_kinds).and_raise(ActiveRecord::ConnectionNotEstablished)
        expect(service.call[:jobs]).to be(false)
      end
    end
  end

  describe "storage" do
    it "is on when a file can be written, read back and deleted, and leaves nothing behind" do
      blob_service = ActiveStorage::Blob.service
      expect(blob_service).to receive(:delete).with(a_string_starting_with("services-health-check-")).and_call_original

      expect(service.call[:storage]).to be(true)
      expect(Dir.glob(File.join(blob_service.root, "**", "services-health-check-*"))).to be_empty
    end

    it "is off when the disk refuses the write" do
      allow(ActiveStorage::Blob.service).to receive(:upload).and_raise(Errno::EROFS)
      expect(service.call[:storage]).to be(false)
    end
  end
end
