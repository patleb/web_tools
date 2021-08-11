module Checks
  module Linux
    class Ruby < WorkerGroup
      def self.list
        [inherited_group]
      end

      def pids_issue?
        return unless File.exist? "/etc/nginx/sites-enabled/#{MixServer.config.deploy_dir}"
        return unless (nginx_conf = Pathname.new("/etc/nginx/sites-available/#{MixServer.config.deploy_dir}")).exist?
        return unless nginx_conf.readlines.none?{ |line| line.match? /^\s*return 503;/ }
        return unless self.class.host.uptime > Setting[:check_interval]
        return unless (Time.current - Server.current.created_at) > Setting[:check_interval]
        minimum = MixServer.config.minimum_workers + Setting[:check_from_cron].to_i
        pids < minimum
      end
    end
  end
end
