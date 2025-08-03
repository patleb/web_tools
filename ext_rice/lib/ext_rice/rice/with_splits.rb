module Rice
  module WithSplits
    COMMENT = %r{ *(?:/\*|\*/|//|$)} # or end line
    ACCESS  = / *(?:public|protected|private)/
    MACRO   = /#/
    INDENT  = /^( *)/
    CLASS   = /(?:class|struct) +(\w+)/
    BASE    = /(\w*)/
    CODE    = /([^ ].*)/
    END_SCOPE = /[^{]*} *;?/
    INLINE    = /(?:\) *\{ *}|; *})/
    STATEMENT = /;/
    METHOD    = /^[^;]+$/
    LAST_CHAR = / *(?:\{(?!.*\{)|:? *$)/
    KEYWORDS  = /(?:(\W)(?:explicit|static|virtual) | (?:override|final)(\W))/
    NAME      = / (~?\w+|operator\W+)\(/
    CONTEXT   = 'CONTEXT(trace, source)'
    PARAMS    = 'const std::stacktrace & trace, const std::source_location & source'
    DEFAULTS  = / += *[^,)]+([,)])/

    def split_files
      filter(dst_path.glob('**/*.hpp')).each do |file|
        next if file.sub_ext('.cpp').exist?
        lines = file.readlines
        next if lines.empty?
        next unless ENV['SPLIT_SRC'].to_b || lines[0].match?(%r{^/* SPLIT */$})
        next unless (cls_step = lines.find{ |line| line[/^ +class /] })
        step = cls_step[/^ +/].size
        cls_count = lines.count{ |line| line[/^ {#{step}}class [^;]+$/] }
        hpp, cpp, scopes, mod, cls, split = [], Array.new(cls_count){ [] }, [], nil, nil, false
        cls_names, cls_i = {}, 0
        lines.each do |line|
          case line
          when /^(?:#{COMMENT}|#{ACCESS}:|#{MACRO})/
            hpp << line
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
            cls ||= (cls_names[mod] << name ;name) if indent == step
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
              cls, cls_i = nil, cls_i + 1 if indent == step
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
                  line.sub(KEYWORDS, '\1').sub(NAME, " #{name}::\\1(").sub(CONTEXT, PARAMS).gsub(DEFAULTS, '\1')
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
          names.each do |name|
            code = cpp[cls_i]
            file.sub_ext("_#{mod.underscore}_#{name.underscore}.cpp").open('w') do |f|
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
  end
end
