module ActiveRecord::Base::WithAdmin
  extend ActiveSupport::Concern

  class_methods do
    def rails_admin_blocks
      @rails_admin_blocks ||= { before: {}, after: {} }.with_keyword_access
    end

    def inherited(subclass)
      super
      if (model_name = subclass.name)
        if "#{subclass.base_class.name}Admin".to_const && !subclass.base_class?
          has_base_class_admin = true
          subclass.rails_admin_prepend subclass.base_class, :base_class
        end
        if "#{subclass.superclass.name}Admin".to_const && !subclass.superclass.base_class?
          has_superclass_admin = true
          subclass.rails_admin_prepend subclass.superclass, :superclass
        end
        if (admin_concern = "#{model_name}Admin".to_const)
          subclass.include admin_concern
        end
        if has_base_class_admin
          subclass.rails_admin_include subclass.base_class, :base_class
        end
        if has_superclass_admin
          subclass.rails_admin_include subclass.superclass, :superclass
        end
      end
    end

    def rails_admin_prepend(model, name = :self)
      if model.rails_admin_blocks[:before].has_key? name
        model.rails_admin_blocks[:before][name].each do |block|
          rails_admin(name, &block)
        end
      end
    end

    def rails_admin_include(model, name = :self)
      if model.rails_admin_blocks[:after].has_key? name
        model.rails_admin_blocks[:after][name].each do |block|
          rails_admin(name, &block)
        end
      end
    end

    def rails_admin(name = :self, before: true, after: nil, &block)
      before_or_after = (before && after.blank?) ? :before : :after
      (rails_admin_blocks[before_or_after][name] ||= SortedSet.new) << block
      RailsAdmin.model(self, &block)
    end
  end

  def rails_admin_object_label
    new_record? ? "#{I18n.t('admin.misc.new')} #{model_name.human}" : "#{model_name.human} ##{id}"
  end

  def safe_send(value)
    if !json_attribute?(value) && has_attribute?(value)
      self[value]
    else
      send(value)
    end
  end
end
