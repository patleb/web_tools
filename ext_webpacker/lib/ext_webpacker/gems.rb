module ExtWebpacker
  module Gems
    extend self

    def install
      source_gems_path.mkdir unless source_gems_path.exist?
      source_gems_path.children.select(&:symlink?).each(&:delete)
      watched_symlinks = gems.map do |(name, path)|
        symlink = source_gems_path.join(name)
        File.symlink(path, symlink)
        symlink.join("**/*{#{watched_extensions}}").to_s
      end
      Webpacker::Compiler.watched_paths.concat(watched_symlinks)
    end

    def gems
      @gems ||= begin
        paths = (default_config['gems'] || []).map{ |name| [name, Gem.root(name).join(gems_source_path)] }
        paths.select!{ |(_name, path)| path.exist? }
        paths
      end
    end

    def gems_source_path
      @gems_source_path ||= default_config['gems_source_path'] || 'lib/javascript'
    end

    def source_gems_path
      @source_gems_path ||= source_path.join(default_config['source_gems_path'] || 'gems')
    end

    def source_path
      @source_path ||= Pathname.new(default_config['source_path'])
    end

    def watched_extensions
      @watched_extensions ||= default_config['extensions'].join(',')
    end

    def default_config
      @default_config ||= YAML.load(Pathname.new('config/webpacker.yml').read)['default']
    end
  end
end
