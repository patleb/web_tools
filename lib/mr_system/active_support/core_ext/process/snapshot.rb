module Process
  module Snapshot
    def snapshot
      self.class.const_get(:SNAPSHOT).each_with_object({}) do |attr, memo|
        memo[attr] =
          case attr.to_s
          when /_time$/
            send(attr).utc
          else
            send(attr)
          end
      end
    end

    def snapshot!
      @_snapshot = snapshot
    end

    def snapshot_diff(old_snapshot = @_snapshot)
      return unless old_snapshot
      new_snapshot = snapshot
      new_snapshot.slice(*self.class.const_get(:SNAPSHOT_DIFF)).each_with_object({}) do |(attr, value), memo|
        memo[attr] =
          case value
          when Array
            value.map.with_index{ |v, i| (v - old_snapshot[attr][i]).ceil(3) }
          else
            (value - old_snapshot[attr]).ceil(3)
          end
      end
    end
  end
end
