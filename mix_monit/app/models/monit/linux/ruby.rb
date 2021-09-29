module Monit
  module Linux
    class Ruby < WorkerGroup
      def self.list
        [inherited_group]
      end

      def pids_issue?
        return unless File.exist? "/etc/nginx/sites-enabled/#{MixServer.deploy_dir}"
        return unless (nginx_conf = Pathname.new("/etc/nginx/sites-available/#{MixServer.deploy_dir}")).exist?
        return unless nginx_conf.readlines.none?{ |line| line.match? /^\s*return 503;/ }
        return unless self.class.host.uptime > 5.minutes
        return unless Server.provisioned?
        minimum = MixServer.config.minimum_workers + Setting[:monit_from_cron].to_i
        pids < minimum
      end
    end
  end
end
