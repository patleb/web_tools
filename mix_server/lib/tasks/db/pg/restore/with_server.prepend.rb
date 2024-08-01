module Db::Pg::Restore::WithServer
  extend ActiveSupport::Concern

  class_methods do
    def self.args
      super.merge!(
        new_server: ['--[no-]new-server', 'Reset current server centralized log'],
      )
    end
  end

  def post_restore_environment
    super
    Server.current.discard! if options.new_server && !Server.current.new?
  end
end
