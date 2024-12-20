module MonkeyPatch
  SNAPSHOTS_DIR = 'tmp/test/monkey_patches'

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
    snapshots_dir = Pathname.new(SNAPSHOTS_DIR)
    snapshots_dir.mkdir_p
    snapshots = snapshots_dir.children
    errors = @files.each_with_object({}) do |(gem_name, files), errors|
      root = Gem.root(gem_name)
      files.each do |file, checksum_was|
        path = root.join(file)
        text = path.read
        checksum = Digest::SHA256.hexdigest(text)
        if checksum == checksum_was
          snapshot = snapshots_dir.join("#{gem_name}~#{file.tr('/', '~')}")
          snapshot.write(text)
          snapshots.delete(snapshot)
        else
          errors[path] = checksum
        end
      end
    end
    errors = @values.each_with_object(errors) do |(path, values), errors|
      values.each do |value, expect|
        errors[path] = value if value != expect
      end
    end
    if errors.empty?
      snapshots.each(&:delete) # remove deprecated snapshots
      return
    end
    raise "\n#{errors.map{ |(path, value)| "#{path}: #{value}" }.join("\n")}\ncount: #{errors.size}"
  end
end
