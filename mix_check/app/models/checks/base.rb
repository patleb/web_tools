module Checks
  class Base < VirtualRecord::Base
    enum level: LogMessage.levels.slice(:info, :warn, :error), default: :info
  end
end
