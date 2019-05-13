module Kernel
  # TODO 2.6 Binding#source_location
  def caller_location(start = 1)
    caller_locations(2, start)[start - 1]
  end
end
