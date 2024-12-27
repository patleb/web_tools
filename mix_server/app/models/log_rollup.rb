class LogRollup < LibMainRecord
  belongs_to :log

  enum! :type, MixServer::Log.config.available_rollups
end
