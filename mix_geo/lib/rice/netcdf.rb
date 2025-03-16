module NetCDF
  def self.read(path)
    file = File.new(path.to_s)
    yield file
  ensure
    file&.close
  end

  def self.write(path, share = false)
    file = File.new(path.to_s, 'w', share)
    yield file
  ensure
    file&.close
  end

  def self.append(path, share = false)
    file = File.new(path.to_s, 'a', share)
    yield file
  ensure
    file&.close
  end
end
