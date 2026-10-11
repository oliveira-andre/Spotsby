require "open3"

# Each public method is one check: its name is the JSON key, and it returns true or false.
# `app` is always here. The others cover what Spotsby needs in production (see
# config/deploy.yml): Postgres, Solid Cache, Solid Queue running inside Puma, Solid Cable,
# the storage volume for audio and artwork, and ffmpeg for the quick-start clips.
#
# Checks run one after another and the intranet waits 10 seconds for the whole answer,
# so keep each one quick. Helpers go under `private`: a public method becomes a check.
class HealthCheckService
  TIMEOUT = 5

  # A job that has waited longer than this to start means the queue is backed up.
  QUEUE_LATENCY_LIMIT = 5.minutes

  # Solid Queue roles that must be alive: workers run jobs, the dispatcher releases
  # scheduled ones (retries, `wait:`).
  REQUIRED_QUEUE_PROCESSES = %w[Worker Dispatcher].freeze

  def call
    checks.index_with { |name| safely { public_send(name) } }
  end

  # The project answers its own /up (Rails' built-in health page).
  def app
    HTTParty.get(ENV.fetch("SERVICES_HEALTH_CHECK_APP_URL", "http://localhost:#{ENV.fetch("PORT", 3000)}/up"),
                 timeout: TIMEOUT).success?
  end

  # Solid Cable's database answers. It carries the turbo-stream broadcasts that keep
  # "now playing" in sync across a user's devices.
  def cable
    # Outside production the adapter (async, test) runs inside this process.
    return true unless solid_cable?

    SolidCable::Record.connection.select_value("SELECT 1") == 1
  end

  # The cache (Solid Cache in production) stores and returns a value. Rate limits on
  # sign-in count attempts here, so a broken cache also means unthrottled logins.
  def cache
    key = "services_health_check:#{SecureRandom.hex(8)}"
    Rails.cache.write(key, "ok", expires_in: 1.minute)
    Rails.cache.read(key) == "ok"
  ensure
    Rails.cache.delete(key) if key
  end

  # The primary database answers.
  def database
    ActiveRecord::Base.connection.select_value("SELECT 1") == 1
  end

  # ffmpeg runs. AudioFragmentClipper uses it to cut each song's quick-start clip.
  def ffmpeg
    _output, _error, status = Open3.capture3("ffmpeg", "-version")
    status.success?
  end

  # Solid Queue has a live worker and dispatcher (here they run inside Puma, see
  # SOLID_QUEUE_IN_PUMA), and no ready job has waited longer than QUEUE_LATENCY_LIMIT.
  # Jobs cut the quick-start clips and send password and unlock emails.
  def jobs
    # Outside production the adapter (async, test) runs inside this process.
    return true unless solid_queue?

    oldest = oldest_ready_job_at
    (REQUIRED_QUEUE_PROCESSES - live_queue_process_kinds).empty? &&
      (oldest.nil? || oldest > QUEUE_LATENCY_LIMIT.ago)
  end

  # Active Storage can write, read back and delete a file. Song audio and artwork live
  # there (the spotsby_storage volume in production), so a full or read-only disk fails.
  def storage
    service = ActiveStorage::Blob.service
    key = "services-health-check-#{SecureRandom.hex(8)}"
    service.upload(key, StringIO.new("ok"))
    service.download(key) == "ok"
  ensure
    service.delete(key) if service && key
  end

  private
    # `app` first, then the other checks by name.
    def checks
      [ :app, *(self.class.public_instance_methods(false) - [ :call, :app ]).sort ]
    end

    # A check that raises, or returns anything but true, is off. ScriptError covers checks
    # left as `raise NotImplementedError` and a `require` that fails.
    def safely
      yield == true
    rescue StandardError, ScriptError
      false
    end

    def solid_cable?
      ActionCable.server.config.cable&.dig(:adapter) == "solid_cable"
    end

    def solid_queue?
      ActiveJob::Base.queue_adapter_name == "solid_queue"
    end

    def live_queue_process_kinds
      SolidQueue::Process.where(last_heartbeat_at: SolidQueue.process_alive_threshold.ago..)
                         .distinct.pluck(:kind)
    end

    def oldest_ready_job_at
      SolidQueue::ReadyExecution.minimum(:created_at)
    end
end
