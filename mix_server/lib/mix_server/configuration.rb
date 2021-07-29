module MixServer
  has_config do
    attr_writer :available_providers
    attr_writer :minimum_workers

    def available_providers
      @available_providers ||= {
        localhost: 10,
        vagrant: 20,
        aws: 30,
        digital_ocean: 40,
        azure: 50,
        ovh: 60,
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

    def deploy_dir
      @deploy_dir ||= "#{Rails.app}_#{Rails.env}"
    end

    def shared_dir
      if Rails.env.dev_or_test?
        Rails.root
      else
        Rails.root.join('..', '..', 'shared').expand_path
      end
    end
  end
end
