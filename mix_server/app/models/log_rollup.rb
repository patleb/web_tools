class LogRollup < LibMainRecord
  belongs_to :log

  enum! :type, MixServer::Logs.config.available_rollups
end
