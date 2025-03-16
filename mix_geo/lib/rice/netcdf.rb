module NetCDF
  def self.read(path)
    file = File.new(path.to_s)
    yield file
  ensure
    file&.close
  end

  def self.write(path)
    file = File.new(path.to_s, 'w')
    yield file
  ensure
    file&.close
  end

  def self.append(path)
    file = File.new(path.to_s, 'a')
    yield file
  ensure
    file&.close
  end
end
