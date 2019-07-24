require 'thor'
require 'active_support/core_ext/string/inflections'

module MrBackend
  class Cli < Thor
    include Thor::Actions

    VARIABLES = /%([a-z0-9_]+)%/

    attr_reader :plugin_name

    desc 'plugin [name]', 'Create new library'
    def plugin(name)
      @plugin_name = name
      @plugin_path = Pathname.new(name).expand_path
      do_plugin(name)
    end

    no_tasks do
      source_root File.expand_path('../cli/templates/plugin', __FILE__)

      def plugin_module
        @plugin_name.camelize
      end

      def do_plugin(name)
        empty_directory name
        template '%plugin_name%.gemspec'
        template 'MIT-LICENSE'
        template 'README.md'
        template 'lib/%plugin_name%.rb'
        template "lib/%plugin_name%/configuration.rb"
        template "lib/%plugin_name%/engine.rb"
        add_to_manifests
        add_to_gemfile
        add_to_gemspec
      end

      def copy_file(source)
        super source, destination(source)
      end

      def template(source)
        super source, destination(source)
      end

      def destination(source)
        source = @plugin_path.join(source)
        source.to_s.gsub(VARIABLES) do |variable|
          variable.gsub!(/(^%|%$)/, '')
          send(variable)
        end
      end

      def add_to_manifests
        require_line = "# require '#{plugin_name}'\n"
        %w(all).each do |name|
          path = Pathname.new("lib/mr_backend/#{name}.rb")
          lines = path.readlines
          next if lines.include? require_line
          path.write (lines << require_line).sort_by!{ |line| strip_require(line) }.join
        end
      end

      def add_to_gemfile
        before = anchor[:type] == :before
        insert_into_file 'Gemfile',
          "#{"\n" unless before}gem '#{plugin_name}', path: './#{plugin_name}'#{"\n" if before}",
          anchor[:type] => anchor[:value]
      end

      def add_to_gemspec
        path = Pathname.new('mr_backend.gemspec')
        lines = path.readlines.select{ |line| line.include?('s.add_dependency') && line.include?('version') }
        gem = "  s.add_dependency \"#{plugin_name}\", "
        return if lines.any?{ |line| line.include? gem }
        before = anchor[:type] == :before
        biggest = lines.max_by(&:size).size - "version\n".size
        pad = biggest - gem.size
        pad = pad < 0 ? '' : ' ' * pad
        insert_into_file path,
          "#{"\n" unless before}#{gem}#{pad}version#{"\n" if before}",
          anchor[:type] => anchor[:value]
      end

      def anchor
        @anchor ||= begin
          lines = Pathname.new('lib/mr_backend/all.rb').readlines
          index = lines.index{ |line| line.include? "'#{plugin_name}'" }
          before = index < lines.size - 1
          lines.map!{ |line| strip_require(line) }
          value = (before ? lines[index + 1] : lines[index - 1])
          {
            type: (before ? :before : :after),
            value: /^.+['"]#{value.sub(/ if .+/, '')}['"].*$/,
          }
        end
      end

      def strip_require(line)
        line.gsub(/(# require|require) /, '').gsub(/['"]/, '').strip
      end
    end
  end
end
