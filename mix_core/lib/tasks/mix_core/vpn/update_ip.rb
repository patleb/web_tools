module MixCore
  module Vpn
    class UpdateIp < ActiveTask::Base
      IP = /(?:[0-9]{1,3}\.){3}[0-9]{1,3}/

      class InvalidIp < ::StandardError; end

      def self.steps
        %i(
          validate_ip
          fetch_record
          update_record_ip
        )
      end

      def self.args
        { ip: ['--ip=IP', 'vpn A Record ip'] }
      end

      def validate_ip
        @ip = options.ip.to_s[IP]
        raise InvalidIp, "[#{@ip}]" unless @ip.present?
      end

      def fetch_record
        @record_set = dns_record_sets.find do |record_set|
          record_set.name.chop == Setting[:vpn_domain] && record_set.type == 'A'
        end
      end

      def update_record_ip
        puts "[FROM][#{@record_set.resource_records.first.value}][TO][#{@ip}]"
        dns.change_resource_record_sets(
          change_batch: {
            changes: [{
              action: 'UPSERT', resource_record_set: {
                name: @record_set.name, resource_records: [{ value: @ip }], type: 'A', ttl: 300
              }
            }]
          },
          hosted_zone_id: dns_zone.id
        )
        ExtRake.config.shared_dir.join('vpn_ip').write(@ip)
      end

      protected

      def dns_record_sets
        dns.list_resource_record_sets(hosted_zone_id: dns_zone.id).resource_record_sets
      end

      def dns_zone
        @_dns_zone ||= dns.list_hosted_zones_by_name.hosted_zones.select{ |zone| zone.name.chop == Setting[:dns_domain] }.first
      end

      def dns
        @_dns ||= Aws::Route53::Resource.new(
          region: Setting[:aws_region],
          access_key_id: Setting[:aws_access_key_id],
          secret_access_key: Setting[:aws_secret_access_key],
        ).client
      end
    end
  end
end
