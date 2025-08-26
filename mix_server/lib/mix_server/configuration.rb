require_dir __FILE__, 'configuration'

module MixServer
  def self.current_version
    @current_version ||= begin
      version = Rails.root.join('REVISION')
      version = version.exist? ? version.read : `git rev-parse --short HEAD`
      version.strip.first(7)
    end
  end

  def self.current_version_time
    @current_version_time ||= begin
      time = Rails.root.join('REVISION_TIME')
      time = time.exist? ? time.read : `git log -1 --pretty=format:'%ct' HEAD`
      Time.at(time.strip.to_i)
    end
  end

  def self.no_reboot_file
    Pathname.shared_path('tmp/files', 'no_reboot')
  end

  def self.idle?(timeout: nil)
    return _idle? unless timeout
    started_at = Time.current
    until (idle = _idle?)
      break if (Time.current - started_at) > timeout
      sleep ExtRuby.config.memoized_at_timeout
    end
    idle
  end

  def self._idle?
    # make sure that Passenger extra workers are killed and no extra rake tasks are running
    min_workers = MixServer.config.minimum_workers + 1 # include the current rake task or rails console
    Process.passenger.requests.empty? && Process::Worker.all.select{ |w| w.name == 'ruby' }.size <= min_workers
  end
  private_class_method :_idle?

  has_config do
    attr_writer :render_500
    attr_writer :notice_interval
    attr_writer :skip_notice
    attr_writer :throttler_max_duration
    attr_writer :available_workers
    attr_writer :available_providers
    attr_writer :minimum_workers
    attr_writer :clamav_dirs
    attr_writer :clamav_false_positives

    def render_500
      return @render_500 if defined? @render_500
      @render_500 = !Rails.env.development?
    end
    alias_method :render_500?, :render_500

    def notice_interval
      @notice_interval ||= 24.hours
    end

    def skip_notice
      return @skip_notice if defined? @skip_notice
      @skip_notice = Rails.env.development?
    end

    def throttler_max_duration
      if @throttler_max_duration.is_a? Proc
        @throttler_max_duration.call
      else
        @throttler_max_duration ||= Float::INFINITY.hours
      end
    end

    def available_workers
      @available_workers ||= ['ruby', 'postgres']
    end

    def available_providers
      @available_providers ||= {
        custom:         0,
        localhost:      10,
        multipass:      20,
        aws:            30,
        digital_ocean:  40,
        azure:          50,
        ovh:            60,
      }
    end

    def minimum_workers
      @minimum_workers ||= begin
        count = Setting[:min_instances]
        if Rails.configuration.active_job.queue_adapter == :job && !MixJob.config.async?
          count += 1
        end
        count
      end
    end

    def clamav_dirs
      @clamav_dirs ||= %W(
        /tmp
        /home/#{Setting[:deployer_name]}
        /bin
        /sbin
        /usr/bin
        /usr/sbin
        /usr/local/bin
        /usr/local/sbin
      )
    end

    def clamav_false_positives
      @clamav_false_positives ||= [
        %r{/imurmurhash/}
      ]
    end
  end
end
