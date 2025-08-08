module Rice
  module WithSplits
    DIRECTIVE = /#/
    COMMENT   = %r{ *(?:/\*|\*/|//|$)} # or end line
    INDENT    = /^( *)/
    CLASS     = /(?:class|struct) +(\w+)/
    ACCESS    = / *(?:public|protected|private)/
    BASE      = /(\w*)/
    CODE      = /([^ ].*)/
    END_SCOPE = /[^{]*} *;?/
    INLINE    = /(?:\) *\{ *}|; *})/
    STATEMENT = /;/
    METHOD    = /^[^;]+$/
    LAST_CHAR = / *(?:\{(?!.*\{)|:? *$)/
    KEYWORD   = /(?:(\W)(?:explicit|static|virtual) | (?:override|final)(\W))/
    NAME      = / (~?\w+|operator\W+)\(/
    CONTEXT   = 'CONTEXT(trace, source)'
    MACRO     = 'const std::stacktrace & trace, const std::source_location & source'
    DEFAULTS  = / += *[^,)]+([,)])/ # doesn't support constructors or filled initializer lists

    # NOTE extracting the .cpp files is faster if the files are faster to compile than the mods and M mods < J jobs
    #  --> otherwise, just split by modules
    def split_files
      filter(dst_path.glob('**/*.hpp')).each do |file|
        next if file.sub_ext('.cpp').exist?
        lines = file.readlines
        next if lines.empty?
        next if     (first = lines[0]).match? %r{^/\** NO_SPLIT *\*/$}
        next unless (split_all = first.match?(%r{^/\** SPLIT_ALL *\*/$}) ||  ENV['SPLIT_SRC']&.downcase == 'all') ||
                                 first.match?(%r{^/\** SPLIT *\*/$})     || (ENV['SPLIT_SRC'] || true).to_b
        next unless (cls_step = lines.find{ |line| line[/^ +(class|struct) /] })
        step = cls_step[/^ +/].size
        cls_count = split_all ? lines.count{ |line| line[/^ {#{step}}class [^;]+$/] } : 1
        hpp, cpp, scopes, mod, cls, split = [], Array.new(cls_count){ [] }, [], nil, nil, false
        cls_names, cls_i = {}, 0
        lines.each do |line|
          case line
          when /^(?:#{DIRECTIVE}|#{COMMENT})/
            case scopes.dig(-1, 0)
            when :method
              cpp[cls_i] << line
            else
              hpp << line
            end
          when /^ *template *</
            scopes << [:template]
            hpp << line
          when /#{INDENT}namespace(?: *{?| +(\w+) *{?)#{COMMENT}/
            indent, name = $1.size, $2.presence
            scopes << [:namespace, indent]
            mod ||= (cls_names[name] ||= [] ;name) if indent == 0
            hpp << line
            cpp.each(&:<<.with(line))
          when /#{INDENT}#{CLASS} *:?#{ACCESS}? *#{BASE} *{?#{COMMENT}/
            indent, name, base = $1.size, $2, $3.presence
            template = scopes.pop && :template if scopes.dig(-1, 0) == :template
            scopes << [:class, indent, name, base, template]
            cls ||= (split_all ? (cls_names[mod] << name; name) : (cls_names[mod] = [nil]; '')) if indent == step
            hpp << line
          when /#{INDENT}#{END_SCOPE}#{COMMENT}/
            indent = $1.size
            indent_was = scopes.dig(-1, 1) || 0
            case scopes.dig(-1, 0)
            when :namespace
              hpp << line
              cpp.each(&:<<.with(line)) if indent == indent_was
              mod = nil if indent == 0
            when :class
              hpp << line
              cls, cls_i = nil, cls_i + 1 if split_all && indent == step
            when :method
              cpp[cls_i] << (indent == indent_was ? line.lstrip.indent(indent_was) : line)
            else
              hpp << line
            end
            scopes.pop if indent == indent_was
          when /#{INDENT}#{CODE}#{COMMENT}/
            template = scopes.pop && :template if scopes.dig(-1, 0) == :template
            next hpp << line if scopes.dig(-1, -1) == :template
            indent, code = $1.size, $2
            indent_was = scopes.dig(-1, 1) || 0
            case scopes.dig(-1, 0)
            when :namespace, :class
              next hpp << line unless indent == indent_was + step
              name = scopes.dig(-1, 2)
              case code
              when /^inline / then hpp << line
              when INLINE     then hpp << (code.include?(name) ? line : "#{' ' * indent}inline #{line.lstrip}")
              when STATEMENT  then hpp << line
              when METHOD
                next hpp << line if template || code.exclude?('(')
                hpp << line.sub(LAST_CHAR, ';')
                cpp[cls_i] << if scopes.dig(i = -1, 0) == :class
                  name = "#{scopes.dig(i, 2)}::#{name}" while scopes.dig(i -= 1, 0) == :class
                  line.sub(KEYWORD, '\1').sub(NAME, " #{name}::\\1(").sub(CONTEXT, MACRO).gsub(DEFAULTS, '\1')
                else
                  line
                end.lstrip.indent(indent)
                split = true
                scopes << [:method, indent]
              else
                hpp << line
              end
            when :method
              cpp[cls_i] << line
            else
              hpp << line
            end
          else
            hpp << line
          end
        end
        next unless split
        file.write(hpp.join)
        cls_i = 0
        cls_names.each do |mod, names|
          count = names.size
          names.each do |name|
            code = cpp[cls_i]
            file.sub_ext(count > 1 && name ? "_#{name.underscore}.cpp" : '.cpp').open('w') do |f|
              f.puts <<~CPP
                #{pch.exist? ? '#include "precompiled.hpp"' : include_headers}
                #include "all.hpp"

              CPP
              f.puts code
            end
            cls_i += 1
          end
        end
      end
    end

    # NOTE separating by classes is faster if the mods are faster to compile than the classes and N classes < J jobs
    #  --> otherwise, just split by modules
    def create_and_split_init_file
      split_all   = ENV['SPLIT_MOD']&.downcase == 'all'
      mod_targets = split_all || (ENV['SPLIT_MOD'] || true).to_b ? self.module_targets : {}
      cls_targets = split_all ? self.class_targets : {}
      includes = <<~CPP
        #{pch.exist? ? '#include "precompiled.hpp"' : include_headers}
        #include "all.hpp"
        #include "ext_rice/rice.hpp"
        #{hook :after_include}
        using namespace Rice;
      CPP
      write_source = -> (mod_key, name, defs, weight) do
        dst_path.join("#{weight}_#{name}.cpp").open('w') do |f|
          f.puts <<~CPP
            #include "#{name}.hpp"
  
            extern "C" void init_#{name}() {
          CPP
          define_properties(f, nil, { mod_key => defs })
          f.puts <<~CPP
            }
          CPP
        end
      end
      write_header = -> (name) do
        dst_path.join("#{name}.hpp").open('w') do |f|
          f.puts <<~HPP
            #pragma once
  
            #{includes}
            extern "C" void init_#{name}();
          HPP
        end
      end
      mod_names, cls_names = [], []
      gems_config[:defs].slice(*mod_targets.keys).each do |mod_key, cls|
        mod_name = mod_targets[mod_key]
        mod_names << mod_name
        write_source.(mod_key, mod_name, cls.except(*cls_targets[mod_key]&.keys), '01')
        write_header.(mod_name)
        cls_targets[mod_key]&.each do |cls_key, cls_name|
          cls_names << cls_name
          write_source.(mod_key, cls_name, cls.slice(cls_key), '02')
          write_header.(cls_name)
        end
      end
      dst_path.join("00_#{target}.cpp").open('w') do |f|
        f.puts includes
        f.puts '// modules' unless mod_names.empty?
        f.puts mod_names.map{ |name| %{#include "#{name}.hpp"} }
        f.puts '// classes' unless cls_names.empty?
        f.puts cls_names.map{ |name| %{#include "#{name}.hpp"} }
        f.puts <<~CPP

          extern "C" void Init_#{target}() {
            #{hook :before_initialize, indent: 2}
            #{hook :initialize,        indent: 2}
        CPP
        gems_config[:rescue_handler].each do |handler|
          f.puts <<~CPP.indent(2)
            detail::Registries::instance.handlers.set(#{handler}());
          CPP
        end
        define_properties(f, nil, gems_config[:defs].except(*mod_targets.keys))
        f.puts mod_names.map{ |name| "  init_#{name}();" }
        f.puts cls_names.map{ |name| "  init_#{name}();" }
        f.puts <<~CPP
            #{hook :after_initialize,  indent: 2}
          }
        CPP
      end
    end

    def module_targets
      @module_targets ||= gems_config[:defs].select_map do |mod_key, defs|
        next unless mod_key.start_with?('module ') && defs&.any?{ |cls, _| cls.start_with?('class ' ) }
        mod_name = "#{target}_#{mod_key.sub(/^module +/, '').underscore}"
        [mod_key, mod_name]
      end.to_h
    end

    def class_targets
      @class_targets ||= module_targets.each_with_object({}) do |(mod_key, mod_name), targets|
        gems_config[:defs][mod_key].each_key do |cls_key|
          next unless cls_key.start_with?('class ' )
          cls_name = "#{mod_name}_#{cls_key.split(/ +/)[1].underscore}"
          ((targets ||= {})[mod_key] ||= {})[cls_key] = cls_name
        end
      end
    end

    def include_headers
      [ hook(:before_include),
        '//include'
      ].concat(gems_config[:include].map do |header|
        header.start_with?('#') ? header : %{#include "#{header.strip}"}
      end).join("\n")
    end

    def hook(name, indent: 0)
      text = hooks[name].strip.presence
      ["// #{name}", ("\n" if text), text&.indent(indent)].join('')
    end
  end
end
