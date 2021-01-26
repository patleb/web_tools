module Process
  module Snapshot
    def snapshot_namespace
      @snapshot_namespace ||= self.class.name.demodulize.underscore
    end

    def snapshot
      @_snapshot
    end

    def snapshot!
      @_snapshot = build_snapshot
    end

    def snapshot?
      !!@_snapshot
    end

    def build_snapshot
      ExtRuby.config.send("#{snapshot_namespace}_snapshot").each_with_object(created_at: Time.now) do |attr, memo|
        memo[attr] =
          case attr.to_s
          when /_(time|at)$/
            send(attr).utc
          else
            send(attr)
          end
      end
    end
  end
end
