class Pathname
  def self.shared_path(root, path = nil)
    full_path = if Setting.local?
      Bundler.root.join(root)
    else
      Bundler.root.join('..', '..', 'shared').expand_path.join(root.to_s.gsub('/', '~'))
    end
    full_path = full_path.join(path) if path
    full_path
  end
end
