module MonkeyPatch
  def self.add
    return unless Rails.env.test?
    path, value, expect = yield
    if path.start_with? '/'
      ((@values ||= {})[path] ||= {})[value] = expect
    else
      gem_name, file, checksum = path, value, expect
      ((@files ||= {})[gem_name] ||= {})[file] = checksum
    end
  end

  def self.verify_all!
    return unless (@files ||= {}).present? || (@values ||= {}).present?
    errors = @files.each_with_object({}) do |(gem_name, files), errors|
      root = Gem.root(gem_name)
      files.each do |file, checksum_was|
        path = root.join(file)
        checksum = Digest::SHA256.hexdigest(path.read)
        errors[path] = checksum if checksum != checksum_was
      end
    end
    errors = @values.each_with_object(errors) do |(path, values), errors|
      values.each do |value, expect|
        errors[path] = value if value != expect
      end
    end
    return if errors.empty?
    raise "\n#{errors.map{ |(path, value)| "#{path}: #{value}" }.join("\n")}\ncount: #{errors.size}"
  end
end
