### NOTE
# echo 'set history save on' >> ~/.gdbinit
# DEBUG=1 rake:test_compile
# gdb -q tmp/rice/test/.../unittest
module Rice
  extend WithGems

  class InvalidChecksum < ::StandardError; end

  CHECKSUM = /^[\da-f]{64}$/
  RB_CONSTANT = /((::)?[A-Z]\w*)+/
  CPP_CONSTANT = /((::)?[a-zA-Z][\w <:>]*)+/
  ALIAS = / +\| +/
  INHERIT = / +< +/
  STATIC = /^static +/
  TEMPLATE = /^<([\w:<>, ]+)> */
  SCOPE_KEYWORDS = /^(module|class) +#{RB_CONSTANT}(#{ALIAS}#{CPP_CONSTANT})?(#{INHERIT}#{CPP_CONSTANT})?$/
  ENUM_KEYWORD = /^enum!? +#{RB_CONSTANT}(#{ALIAS}#{CPP_CONSTANT})?$/
  CONSTANT_KEYWORD = /^[A-Z_][A-Z\d_]+$/
  ATTRIBUTES_KEYWORDS = /^c?attr_(accessor|reader|writer)!?$/
  METHODS_KEYWORD = /^def!?$/
  MEMORY_ACTIONS = {
    'NO_COLLECT' => 'keepAlive()',
    'NO_DELETE'  => 'takeOwnership()',
    'AS_VALUE'   => 'setValue()',
    'AS_OPAQUE'  => 'setOpaque()'
  }

  def self.require_ext
    old_env = ENV['RAILS_ENV']
    if test?
      ENV['RAILS_ENV'] = 'development'
      raise 'rice:compile error' unless system('rake rice:compile') if require_ext?
    end
    return unless require_ext? && bin_path.exist?
    require bin_path
    require_overrides
  ensure
    ENV['RAILS_ENV'] = old_env
  end

  def self.require_ext?
    !ENV['NO_EXT']
  end

  def self.require_numo
    return unless require_numo?
    require "numo/narray"
    numo = File.join(Gem.loaded_specs["numo-narray"].require_path, "numo")
    include_dir numo
  end

  def self.require_numo?
    !ENV['NO_NUMO']
  end

  class << self
    delegate :target, :target_path, :bin_path, :tmp_path, :checksum_path, :mkmf_path, :test?, :executable?, to: 'ExtRice.config'
  end

  def self.create_makefile(cflags: nil, libs: nil, vpaths: nil, dry_run: false)
    copy_files
    require_numo
    include_dir dst_path
    include_dirs, add_libraries, makefile = gems_config.values_at(:include_dir, :libs, :makefile)
    include_dirs.each{ |name| include_dir name }
    add_libraries.each{ |name| add_library name }
    yield(dst_path) if block_given?
    create_init_file unless executable?
    unless dry_run
      $CXXFLAGS += " $(optflags)" # -O3 -ffast-math -fno-associative-math
      $CXXFLAGS += " #{makefile[:cflags]}" if makefile[:cflags].present?
      $CXXFLAGS += " #{cflags}" if cflags
      $CXXFLAGS += " -O0" if ENV['DEBUG']
      $libs += " #{makefile[:libs]}" if makefile[:libs].present?
      $libs += " #{libs}" if libs
      $srcs = Dir["#{dst_path}/**/*.{c,cc,cpp}"]
      $objs = $srcs.map{ |v| v.sub(/c+p*$/, "o") }
      $VPATH.concat(Array.wrap(makefile[:vpaths]).map(&:to_s))
      $VPATH.concat(Array.wrap(vpaths).map(&:to_s))
      if executable?
        MakeMakefile.create_makefile(target, dst_path.to_s) do |conf|
          conf << "\n"
          conf << "#{target}: $(OBJS)"
          conf << "\t$(ECHO) linking executable #{target}"
          conf << "\t-$(Q)$(RM) $(@)"
          conf << "\t$(Q) $(CXX) -o $@ $(OBJS) $(LIBPATH) $(LOCAL_LIBS) $(LIBS)"
          conf << "\n"
        end
      else
        MakeMakefile.create_makefile(target, dst_path.to_s)
      end
    end
  end

  def self.write_checksum
    checksum_path.write(checksum)
  end

  def self.checksum_changed?
    checksum_was != checksum
  end

  def self.checksum
    @checksum_sum ||= begin
      sum = `cd #{tmp_path} && tar --mtime='1970-01-01' --exclude='*.o' -cf - src #{mkmf_path.basename}/Makefile | sha256sum | awk '{ print $1 }'`.strip
      raise InvalidChecksum unless sum.match? CHECKSUM
      sum
    end
  end

  def self.checksum_was
    if checksum_path.exist?
      sum = checksum_path.read
      raise InvalidChecksum unless sum.match? CHECKSUM
      sum
    end
  end

  def self.create_init_file
    includes, rescue_handlers = gems_config.values_at(:include, :rescue_handler)
    dst_path.join("#{target}.cpp").open('w') do |f|
      f.puts <<~CPP
        #{hook :before_include}
        // include
        #{includes.map{ |header| %{#include "#{header.strip}"} }.join("\n")}
        #include "all.hpp"
        #{hook :after_include}
        using namespace Rice;

        extern "C"
        void Init_#{target}() {
          #{hook :before_initialize, indent: 2}
          #{hook :initialize,        indent: 2}
      CPP
      rescue_handlers.each do |handler|
        f.puts <<~CPP.indent(2)
          detail::Registries::instance.handlers.set(#{handler}());
      CPP
      end
      define_properties(f, nil, gems_config[:defs])
      f.puts <<~CPP
          #{hook :after_initialize,  indent: 2}
        }
      CPP
    end
  end

  def self.hook(name, indent: 0)
    text = hooks[name].strip.presence
    ["// #{name}", ("\n#{' ' * indent}" if text), text].join('')
  end

  def self.hooks
    @hooks ||= gems_config[:hooks]
  end

  # TODO registry, iterator, director, etc.
  def self.define_properties(f, parent_var, hash)
    hash.each do |keyword, body|
      case keyword
      when SCOPE_KEYWORDS
        define_self(f, parent_var, keyword, body)
      when ENUM_KEYWORD
        define_enum(f, parent_var, keyword, body)
      when CONSTANT_KEYWORD
        define_constant(f, parent_var, keyword, body)
      when ATTRIBUTES_KEYWORDS
        define_attributes(f, parent_var, keyword, body)
      when METHODS_KEYWORD
        define_methods(f, parent_var, keyword, body)
      else
        raise "invalid keyword [#{keyword}]"
      end
    end
  end

  def self.define_self(f, parent_var, scope, body)
    case body
    when Hash
      parent_var = define_scope(f, parent_var, scope)
      define_properties(f, parent_var, body)
    when nil
      define_scope(f, parent_var, scope)
    else
      raise "invalid body type [#{body.class.name}]"
    end
  end

  def self.define_scope(f, parent_var, scope)
    scope_type, scope_name = scope.split(/ +/, 2)
    return define_module(f, parent_var, scope_name) if scope_type == 'module'

    scope_name, scope_alias = scope_name.split(ALIAS, 2)
    scope_alias ||= extract_full_scope_alias(parent_var, scope_name)
    scope_alias, scope_base = scope_alias.split(INHERIT, 2)
    scope_name = scope_name.split(INHERIT, 2).first
    cpp_class = scope_base ? "<#{scope_alias}, #{scope_base}>" : "<#{scope_alias}>"
    scope_var = build_scope_var('class', scope_alias)
    if parent_var
      f.puts <<~CPP.squish.indent(2)
        Data_Type<#{scope_alias}> #{scope_var} = define_class_under#{cpp_class}(#{parent_var}, "#{scope_name}");
      CPP
    else
      f.puts <<~CPP.squish.indent(2)
        Data_Type<#{scope_alias}> #{scope_var} = define_class#{cpp_class}("#{scope_name}");
      CPP
    end
    scope_var
  end

  def self.define_module(f, parent_var, scope_name)
    scope_name, scope_alias = scope_name.split(ALIAS, 2)
    scope_alias ||= extract_full_scope_alias(parent_var, scope_name)
    scope_var = build_scope_var('module', scope_alias)
    if parent_var
      f.puts <<~CPP.indent(2)
        Module #{scope_var} = define_module_under(#{parent_var}, "#{scope_name}");
      CPP
    else
      f.puts <<~CPP.indent(2)
        Module #{scope_var} = define_module("#{scope_name}");
      CPP
    end
    scope_var
  end

  def self.define_enum(f, parent_var, name, values)
    format = name.include?('!')
    name, name_alias = name.split(/ +/, 2).last.split(ALIAS, 2)
    name_alias ||= name
    enum_var = build_scope_var('enum', name_alias)
    if parent_var
      f.puts <<~CPP.indent(2)
        Enum<#{name_alias}> #{enum_var} = define_enum_under<#{name_alias}>("#{name}", #{parent_var});
      CPP
    else
      f.puts <<~CPP.indent(2)
        Enum<#{name_alias}> #{enum_var} = define_enum<#{name_alias}>("#{name}");
      CPP
    end
    values.each do |value|
      value, value_alias = value.split(ALIAS, 2)
      value_alias ||= value
      value = value.underscore.upcase if format
      f.puts <<~CPP.indent(2)
        #{enum_var}.define_value("#{value}", #{name_alias}::#{value_alias});
      CPP
    end
  end

  def self.define_constant(f, scope_var, name, value)
    raise "can't define a constant on the global scope" unless scope_var
    f.puts <<~CPP.indent(2)
      #{scope_var}.define_constant("#{name}", #{value});
    CPP
  end

  def self.define_attributes(f, scope_var, attr_type, names)
    raise "can't define attributes on the global scope" unless scope_var
    scope_alias = extract_scope_alias(scope_var)
    format = attr_type.end_with?('!')
    singleton = 'singleton_' if attr_type.start_with? 'c'
    access_type = case attr_type
      when /_accessor!?$/ then ''
      when /_reader!?$/   then ', AttrAccess::Read'
      when /_writer!?$/   then ', AttrAccess::Write'
      end
    Array.wrap(names).each do |name|
      name, name_alias = name.split(ALIAS, 2)
      name_alias ||= name
      name = name.underscore if format
      f.puts <<~CPP.indent(2)
        #{scope_var}.define_#{singleton}attr("#{name}", &#{scope_alias}::#{name_alias}#{access_type});
      CPP
    end
  end

  def self.define_methods(f, scope_var, format, names)
    scope_alias = extract_scope_alias(scope_var)
    format = format.end_with?('!')
    dot = '.' if scope_var
    names.each do |name, args|
      is_singleton, name = name.split('self.', 2)
      name, is_singleton = is_singleton, false unless name
      name, name_alias = name.split(ALIAS, 2)
      case name_alias
      when nil
        name_alias = name
      when /\./
        name_alias, *constructors = name_alias.split('.')
      when 'static'
        is_static = !!(name_alias = name)
      when STATIC
        is_static = !!(name_alias.sub! STATIC, '')
      end
      name_alias = "#{scope_alias}::#{name_alias}" if scope_var && name_alias.exclude?('::')
      if scope_var && !is_singleton && !is_static && name == 'initialize' && name_alias.match?(/^(::)?#{scope_alias}$/)
        define_constructors(f, scope_var, scope_alias, constructors, args || [])
        next
      end
      name = name.underscore if format
      function_type = !scope_var ? 'global_function' : ('singleton_function' if is_singleton)
      function_type ||= is_static ? 'function' : 'method'
      case args
      when Array
        if args.first.is_a? Hash
          define_overloads(f, scope_var, dot, function_type, scope_alias, name, name_alias, args)
          next
        elsif args.present?
          defaults = args.map{ |arg| wrap_arg(arg) }.join(', ')
        end
      when Hash
        define_overloads(f, scope_var, dot, function_type, scope_alias, name, name_alias, [args])
        next
      when String
        define_lambda(f, scope_var, dot, function_type, name, args)
        next
      end
      defaults = ", #{defaults}" if defaults
      f.puts <<~CPP.indent(2)
        #{scope_var}#{dot}define_#{function_type}("#{name}", &#{name_alias}#{defaults});
      CPP
    end
  end

  def self.define_constructors(f, scope_var, scope_alias, constructors, args)
    default = false
    Array.wrap(constructors).each do |constructor|
      constructor_alias = extract_constructor_alias(scope_alias, constructor)
      default ||= (constructor == 'DEFAULT')
      f.puts <<~CPP.indent(2)
        #{scope_var}.define_constructor(Constructor<#{constructor_alias}>());
      CPP
    end
    args = [{ args => nil }] unless (args.empty? && default) || args.first.is_a?(Hash)
    args.map{ extract_types_and_defaults(it.keys.first) }.each do |types, defaults|
      types = ", #{types}" if types
      defaults = ", #{defaults}" if defaults
      f.puts <<~CPP.indent(2)
        #{scope_var}.define_constructor(Constructor<#{scope_alias}#{types}>()#{defaults});
      CPP
    end
  end

  def self.define_overloads(f, scope_var, dot, function_type, scope_alias, name, name_alias, args)
    args.map{ extract_return_types_and_defaults(it) }.each do |return_type, types, defaults|
      using_alias = build_using_alias(name_alias)
      return_type, const = return_type.split(/ +const$/, 2)
      template = "<#{$1}>" if (return_type.sub! TEMPLATE, '')
      const = ' const' if const
      f.puts <<~CPP.indent(2)
        using #{using_alias} = #{return_type} (#{scope_alias}::*)(#{types})#{const};
      CPP
      defaults = ", #{defaults}" if defaults
      f.puts <<~CPP.indent(2)
        #{scope_var}#{dot}define_#{function_type}<#{using_alias}>("#{name}", &#{name_alias}#{template}#{defaults});
      CPP
    end
  end

  def self.define_lambda(f, scope_var, dot, function_type, name, args)
    f.puts <<~CPP.indent(2)
      #{scope_var}#{dot}define_#{function_type}("#{name}", #{args.strip});
    CPP
  end

  def self.build_scope_var(scope_type, scope_alias)
    "rb_#{scope_type[0]}#{scope_alias.tr(' ', '').gsub('::', '_dc_').gsub('<', '_lt_').gsub(',', '_c_').gsub('>', '_gt_')}"
  end

  def self.build_using_alias(name_alias)
    (@using_i ||= {})[name_alias] ||= 0
    "rb_#{name_alias.full_underscore}_#{@using_i[name_alias] += 1}"
  end

  def self.extract_full_scope_alias(parent_var, scope_name)
    parent_alias = extract_scope_alias(parent_var)
    parent_var ? "#{parent_alias}::#{scope_name}" : scope_name
  end

  def self.extract_scope_alias(scope_var)
    scope_var.match(/^rb_[mc](\w+)$/)[1].gsub('_dc_', '::').gsub('_lt_', '<').gsub('_c_', ',').gsub('_gt_', '>') if scope_var
  end

  def self.extract_constructor_alias(scope_alias, constructor)
    case constructor
    when 'DEFAULT' then scope_alias
    when 'COPY'    then "const #{scope_alias}&"
    when 'MOVE'    then "#{scope_alias}&&"
    else
      raise "invalid constructor alias [#{constructor}]"
    end
  end

  def self.extract_return_types_and_defaults(args)
    return_type, args = args.first
    return return_type, *extract_types_and_defaults(args)
  end

  def self.extract_types_and_defaults(args)
    case args
    when Array, nil
      args = Array.wrap(args)
      case args.first
      when Array
        args.each_with_object([[], []]) do |arg, (types, defaults)|
          raise "invalid args [#{args}]" if !arg.is_a?(Array) || arg.size != 2
          types << arg.first; defaults << wrap_arg(arg.last)
        end
      when String
        raise "invalid types [#{args.map(&:class)}]" unless args.all?{ |arg| arg.is_a? String }
        [args, nil]
      end&.map{ |a| a.join(', ') if a.present? }
    else
      raise "invalid args type [#{args.class}]"
    end
  end

  def self.wrap_arg(arg)
    name, action = arg.split('.')
    if (action = MEMORY_ACTIONS[action])
      name == 'return' ? "Return.#{action}" : name.sub(/^([a-zA-Z]\w*)( = )?/, %{Arg("\\1").#{action}\\2})
    else
      arg.sub(/^([a-zA-Z]\w*)( = )?/, 'Arg("\1")\2')
    end
  end
end
