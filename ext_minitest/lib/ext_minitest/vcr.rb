require 'vcr'

module VCR
  def self.turned_on(options = {})
    turn_on!

    begin
      yield
    ensure
      turn_off!(options)
    end
  end
end
