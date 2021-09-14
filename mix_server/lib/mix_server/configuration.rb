module MixServer
  has_config do
    attr_writer :available_providers
    attr_writer :minimum_workers
    attr_writer :clamav_dirs
    attr_writer :clamav_false_positives

    def available_providers
      @available_providers ||= {
        custom:         0,
        localhost:      10,
        vagrant:        20,
        aws:            30,
        digital_ocean:  40,
        azure:          50,
        ovh:            60,
        compute_canada: 70
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
