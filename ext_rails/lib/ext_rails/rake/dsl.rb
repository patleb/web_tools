module Rake
  STARTED = '[STARTED]'
  SUCCESS = '[SUCCESS]'
  WARNING = '[WARNING]'
  FAILURE = '[FAILURE]'
  STEP    = '[STEP]'
  CANCEL  = '[CANCEL]'
  RUNNING = '[RUNNING]'

  module DSL
    def puts_info(tag, text = nil, started_at: nil)
      unless respond_to?(:distance_of_time) || self.class.include?(DOTIW::Methods)
        self.class.include DOTIW::Methods
      end
      tag = "[#{tag}]" unless tag.start_with?('[') && tag.end_with?(']')
      text = "[#{Time.current.utc}]#{tag.full_underscore.upcase}[#{Process.pid}] #{text}"
      text = "#{text} -- : #{distance_of_time (Concurrent.monotonic_time - started_at).seconds.ceil(3)}" if started_at
      puts text
    end

    def app_name
      @_app_name ||= Setting.default_app
    end

    def app_secret
      SecureRandom.hex(64)
    end

    def generate_password
      SecureRandom.hex(16)
    end

    def keep(root, force: false)
      root = Pathname.new(root)
      mkdir_p root
      touch root.join('.keep') if force || root.empty?
    end

    def gitignore(root, ignore, verbose: true)
      file = Pathname.new(root).join('.gitignore')
      unless (gitignore = file.read).match? /^#{ignore.escape_regex}$/
        Rake.rake_output_message "gitignore #{ignore}" if verbose
        write file, (gitignore << "\n#{ignore}"), verbose: false
      end
    end

    def write(dst, value, verbose: true)
      Rake.rake_output_message "write #{dst}" if verbose
      Pathname.new(dst).write(value)
    end

    def with_stage!(args, &block)
      raise 'argument [:app] must be specified' unless args[:app].present?
      with_stage(args, &block)
    end

    def with_stage(args)
      raise 'argument [:env] must be specified' unless args[:env].present?
      Setting.with(env: args[:env], app: args[:app]) do
        yield
      end
    end

    def sun_rake(task_name, *args, env: Setting.env, app:, **argv)
      no_color  = ' DISABLE_COLORIZATION=true' if ENV['DISABLE_COLORIZATION'].to_b
      stage     = [env, app].join('_')
      rake_args = args.empty? ? '' : "[#{args.join(',')}]"
      rake_options, sun_options = argv.each_with_object([+'', +'']) do |(key, value), (rake_options, sun_options)|
        case key
        when :host, :wait
          sun_options << " --#{key} #{value}" if value.present?
          next
        when :sudo, :nohup, :verbose, :kill, :force
          sun_options << " --#{key}" if value
          next
        end
        rake_options << case value
          when nil, true  then " --#{key.to_s.dasherize}"
          when false      then " --no-#{key.to_s.dasherize}"
          when Array, Set then " --#{key.to_s.dasherize}=#{value.to_a.join(',')}"
          else                 " --#{key.to_s.dasherize}=#{value}"
          end
      end
      rake_options = " -- #{rake_options}" if rake_options.present?
      rake_task = [task_name, rake_args, no_color, rake_options].join('')
      sh "bin/sun rake #{stage} '#{rake_task.escape_single_quotes}' #{sun_options}"
    end
  end
end
