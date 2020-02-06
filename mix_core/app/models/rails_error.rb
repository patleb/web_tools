class RailsError < RescueError
  def self.rescue_class
    RailsRescue
  end
end
