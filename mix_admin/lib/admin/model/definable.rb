module Admin::Model::Definable
  attr_reader :sections, :groups, :fields

  ([:Base] + Admin::Sections.constants.except(:New)).each do |section|
    section_name = section.to_s.underscore.to_sym
    define_method section_name do |&block|
      section(section_name, &block)
    end
  end

  def new(**locals, &block)
    if block
      section(:new, &block)
    else
      super
    end
  end

  def inherited(subclass)
    super
    if self != Admin::Model
      subclass.ivar(:@super, self)
      inherit_configs(subclass)
    end
  end

  def inherit_configs(subclass)
    parent_ivars = %i(@sections @groups @fields).map!{ |name| [name, ivar(name)] }.to_h
    raise "No field defined in parent admin model presenter [#{name}]" if parent_ivars.compact.empty?
    ivars = { :@sections => {}, :@groups => {}, :@fields => {} }
    sections = ivars[:@sections]
    parent_ivars[:@sections].each do |section_name, section|
      inherit_section_instance(subclass, section, section_name, sections)
    end
    parent_ivars[:@groups].each do |section_name, groups|
      section = ivars[:@sections][section_name]
      section_groups = ivars[:@groups][section_name] = {}
      groups.each do |group_name, group|
        inherit_config_instance(subclass, group, group_name, section, section_groups)
      end
    end
    parent_ivars[:@fields].each do |section_name, fields|
      section = ivars[:@sections][section_name]
      section_groups = ivars[:@groups][section_name]
      section_fields = ivars[:@fields][section_name] = {}
      fields.each do |field_name, field|
        config = inherit_config_instance(subclass, field, field_name, section, section_fields)
        config.group    = section_groups[field.group.name]
        config.through  = field.through   if field.ivar_defined? :@through
        config.as       = field.as        if field.ivar_defined? :@as
        config.editable = field.editable? if field.ivar_defined? :@editable
      end
    end
    ivars.each{ |(name, value)| subclass.ivar(name, value) }
  end

  def section(name = :base, &block)
    raise "can't have nested section definitions" if @section
    name = name.to_sym
    @section = (@sections ||= {})[name] ||= begin
      klass = (klass_name = "#{self.name}::#{name.to_s.camelize}Section").to_const
      klass ||= context_class(self.klass.superclass, name).to_const
      klass ||= context_class(self.klass.base_class, name).to_const
      klass ||= section_class(name)
      create_section_instance(name, klass, klass_name)
    end
    @section.instance_eval(&block) if block
    @section
  ensure
    remove_ivar(:@section)
  end

  def group!(name = :default, **, &)
    @grouped = true
    group(name, **, &)
  ensure
    remove_ivar(:@grouped)
  end

  def group(name = :default, **options, &block)
    raise "can't have nested group definitions" if @group
    name = name.to_sym
    if @section
      @group = ((@groups ||= {})[@section.name] ||= {})[name] ||= begin
        klass = (klass_name = "#{@section.class.name}::#{name.to_s.camelize}Group").to_const
        klass ||= context_class(self.klass.superclass, @section.name, group: name).to_const
        klass ||= context_class(self.klass.base_class, @section.name, group: name).to_const
        klass ||= group_class(name)
        create_config_instance(@groups, :groups, name, klass, klass_name)
      end
      @group.weight = options[:weight] if options[:weight]
      @group.label(false) if options[:label] == false
      @group.instance_eval(&block) if block
      @group
    else
      section{ group(name, **options, &block) }
    end
  ensure
    remove_ivar(:@group)
  end

  def nests(name, weight: nil, as: nil, **)
    @through = name.to_sym
    @weight = weight
    if block_given?
      yield
    else
      field(as || associations_hash[name].primary_key, **)
    end
  ensure
    remove_ivar(:@through)
    remove_ivar(:@weight)
  end

  def field!(name, **, &)
    field(name, **, editable: true, &)
  end

  def field(name, translated: false, **options, &block)
    raise "can't have nested field definitions" if @field
    name = name.to_sym
    if translated
      field(name, **options.except(:editable), &block) if translated == :all
      I18n.available_locales.each{ |locale| field!("#{name}_#{locale}", **options, &block) }
    else
      if @section
        if @group
          weight = options[:weight] || @weight
          editable = options[:editable]
          if (through = (options[:through] || @through)&.to_sym)
            as, name = name, "#{through}_#{name}".to_sym
          end
          @field = ((@fields ||= {})[@section.name] ||= {})[name] ||= begin
            klass = (klass_name = "#{@section.class.name}::#{name.to_s.camelize}Field").to_const
            klass ||= context_class(self.klass.superclass, @section.name, field: name).to_const
            klass ||= context_class(self.klass.base_class, @section.name, field: name).to_const
            klass ||= field_class(through || name, options[:type])
            create_config_instance(@fields, :fields, name, klass, klass_name)
          end
          @field.weight   = weight     if weight
          @field.group    = @group     if @grouped || @field.group.nil? || @group.name != :default
          @field.through  = through    if through
          @field.as       = as         if as
          @field.editable = editable   if editable.is_a? Boolean
          @field.instance_eval(&block) if block
          @field
        else
          group{ field(name, **options, &block) }
        end
      elsif @group
        section{ field(name, **options, &block) }
      else
        section{ group{ field(name, **options, &block) } }
      end
    end
  ensure
    remove_ivar(:@field)
  end

  def property(name)
    columns_hash[name] || associations_hash[name]
  end

  private

  def create_section_instance(name, klass, klass_name)
    if klass.name != klass_name
      klass_name.clear_const
      klass = Class.new(klass)
      const_set(klass_name.demodulize, klass)
    end
    section = klass.new(name: name, model: self)
    values = section.ivar(:@values)
    section.parent_names.each do |parent_name|
      next unless (parent_section = sections[parent_name])
      values.reverse_merge! parent_section.values_ref
    end
    if superclass != Admin::Model
      if (super_section = superclass.sections[name])
        values.reverse_merge! super_section.values_ref
      end
      section.ivar(:@super, super_section)
    end
    section
  end

  def create_config_instance(configs, configs_name, name, klass, klass_name)
    if klass.name != klass_name
      klass_name.clear_const
      klass = Class.new(klass)
      @section.class.const_set(klass_name.demodulize, klass)
    end
    config = klass.new(name: name, model: self, section: @section, section_was: @section)
    values = config.ivar(:@values)
    weight = configs[@section.name].size
    @section.parent_names.each do |parent_name|
      weight += configs[parent_name]&.size.to_i
      next unless (parent_config = configs.dig(parent_name, name))
      values.reverse_merge! parent_config.values_ref
    end
    config.weight = weight
    if superclass != Admin::Model
      if (super_config = superclass.public_send(configs_name).dig(@section.name, name))
        values.reverse_merge! super_config.values_ref
      end
      config.ivar(:@super, super_config)
    end
    config
  end

  def inherit_section_instance(subclass, instance, name, sections)
    section_class = Class.new(instance.class)
    silence_warnings{ subclass.const_set(instance.class.name.demodulize, section_class) }
    section = section_class.new(name: name, model: subclass)
    sections[name] = section
    section.ivar(:@values, instance.values_ref)
    section.ivar(:@super, instance)
  end

  def inherit_config_instance(subclass, instance, name, section, section_configs)
    config_class = Class.new(instance.class)
    section.class.const_set(instance.class.name.demodulize, config_class)
    config = config_class.new(name: name, model: subclass, section: section, section_was: section)
    config.weight = instance.weight
    section_configs[name] = config
    config.ivar(:@values, instance.values_ref)
    config.ivar(:@super, instance)
    config
  end

  def section_class(name)
    name == :base ? Admin::Section : Admin::Sections.const_get(name.to_s.camelize)
  end

  def group_class(_name)
    Admin::Group
  end

  def field_class(name, type = nil)
    if type.nil? && (property = property(name))
      if (klass = Admin::Field.find_class(@section, property))
        return klass
      end
      type = property.type
    end
    type = MixAdmin.config.field_aliases[type] || type || :string
    Admin::Fields.const_get(type.to_s.camelize)
  end

  def context_class(presenter, section, group: nil, field: nil)
    nodes = { 'Presenter' => presenter.name, 'Section' => section, 'Group' => group, 'Field' => field }.compact
    nodes.reduce('Admin') do |class_name, (type, name)|
      name ? "#{class_name}::#{name.to_s.camelize}#{type}" : class_name
    end
  end
end
