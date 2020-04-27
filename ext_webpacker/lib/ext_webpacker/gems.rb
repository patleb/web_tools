module ExtWebpacker
  module Gems
    extend self

    def install
      prune
      (expected_gems - current_gems).each do |name|
        gem_source_path = Gem.root(name).join(source_path)
        File.symlink(gem_source_path, source_path.join('gems', name)) if gem_source_path.exist?
      end
    end

    def prune
      discarded_gems = current_gems - expected_gems
      symlinks.select{ |symlink| symlink.basename.to_s.in? discarded_gems }.each(&:delete)
    end

    def current_gems
      symlinks.map(&:basename).map(&:to_s)
    end

    def expected_gems
      default_config['gems'] || []
    end

    def symlinks
      root_path.children.select(&:symlink?)
    end

    def root_path
      @root_path ||= begin
        gems_path = Pathname.new(Dir.pwd).join(source_path, 'gems')
        gems_path.mkdir unless gems_path.exist?
        gems_path
      end
    end

    def source_path
      @source_path ||= Pathname.new(default_config['source_path'])
    end

    def default_config
      @default_config ||= YAML.load(Pathname.new('config/webpacker.yml').read)['default']
    end
  end
end
