class LogRollup < LibMainRecord
  belongs_to :log

  enum type: MixLog.config.available_rollups

  attribute :period, :interval # TODO remove in Rails 7.0
end
