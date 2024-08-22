module MonkeyPatch
  def self.add
    return unless Rails.env.test?
    gem_name, file_path, checksum = yield
    ((@files ||= {})[gem_name] ||= {})[file_path] = checksum
  end

  def self.verify_all!
    return unless @files.present?
    errors = @files.each_with_object({}) do |(gem_name, files), errors|
      root = Gem.root(gem_name)
      files.each do |file_path, checksum_was|
        path = root.join(file_path)
        checksum = Digest::SHA256.hexdigest(path.read)
        errors[path] = checksum if checksum != checksum_was
      end
    end
    return if errors.empty?
    raise "\n#{errors.map{ |(path, checksum)| "#{path}: #{checksum}" }.join("\n")}\ncount: #{errors.size}"
  end
end
