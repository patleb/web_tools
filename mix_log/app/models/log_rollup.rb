class LogRollup < LibRecord
  enum type: MixLog.config.available_rollups
end
