class LogRollup < LibMainRecord
  belongs_to :log

  enum! type: MixLog.config.available_rollups
end
