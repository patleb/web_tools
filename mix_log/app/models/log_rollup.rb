class LogRollup < LibRecord
  enum type: MixLog.config.available_rollups

  attribute :period, :interval # TODO remove in Rails 7.0
end
