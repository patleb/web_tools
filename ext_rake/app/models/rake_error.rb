class RakeError < RescueError
  def self.rescue_class
    RakeRescue
  end
end
