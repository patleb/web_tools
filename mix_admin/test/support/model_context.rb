# frozen_string_literal: true

module Test
  class ResourceBase < VirtualRecord::Base
    attribute :base_name
  end

  class ResourceMain < ResourceBase
    attribute :main_name
  end

  class ResourceSibling < ResourceMain
    attribute :sibling_name
  end

  class Resource < ResourceMain
    attribute :name
  end

  class Parent < VirtualRecord::Base
    attribute :name, default: 'parent'
  end

  class ParentBase < Parent; end
  class ParentIndex < Parent; end
  class ParentIndexBase < Parent; end

  class Child < Parent
    attribute :name, default: 'child'
  end

  class ChildParentBase < Child; end
  class ChildParentIndex < Child; end
  class ChildParentIndexBase < Child; end

  class ChildBase < Child; end
  class ChildBaseParentBase < Child; end
  class ChildBaseParentIndex < Child; end
  class ChildBaseParentIndexBase < Child; end

  class ChildIndex < Child; end
  class ChildIndexParentBase < Child; end
  class ChildIndexParentIndex < Child; end
  class ChildIndexParentIndexBase < Child; end

  class ChildIndexBase < Child; end
  class ChildIndexBaseParentBase < Child; end
  class ChildIndexBaseParentIndex < Child; end
  class ChildIndexBaseParentIndexBase < Child; end

  class ChildBaseChildBaseParentBase < Child; end
end

Admin::Section.class_eval do
  register_option :pretty_section do
    "#{name}"
  end
end

module Admin::Test
  class ResourceBasePresenter < Admin::Model
    register_class_option :base_class_memoize, memoize: true do
      'base_class_memoize'
    end

    register_class_option :base_class_accessor, instance_reader: true do
      'base_class_accessor'
    end

    register_class_option :base_class_option do
      'base_class_option'
    end

    register_option :base_option do
      'base_option'
    end

    field :base_name
  end

  class ResourceMainPresenter < ResourceBasePresenter
    register_class_option :base_class_accessor do # overwrite default block, so parent cannot use #super! or __super__
      "main #{super! :base_class_accessor}"
    end

    register_class_option :main_class_memoize, memoize: true do
      'main_class_memoize'
    end

    register_option :main_locale?, memoize: :locale do
      "main_locale_#{I18n.locale}"
    end

    base_class_memoize{ "main #{base_class_memoize}" }
    base_class_option{ "main #{base_class_option}" }

    group :main, weight: 1 do
      field :main_name, weight: 1 do
        allowed{ false }
      end
    end

    index do
      field :base_name
    end
  end

  class ResourceSiblingPresenter < ResourceMainPresenter
    register_option :sibling_option do
      'sibling_option'
    end

    base_class_accessor{ "sibling #{base_class_accessor}" } # overwrite @values block
    main_class_memoize(memoize: false){ "sibling #{main_class_memoize}" }
  end

  class ParentPresenter < Admin::Model
    field :name
  end

  class ParentBasePresenter < Admin::Model
    field :name do
      pretty_value{ "base[parent_base] #{pretty_value}" }
    end

    base do
      pretty_section{ "base[parent_base] #{pretty_section}" }
    end
  end

  class ParentIndexPresenter < Admin::Model
    index do
      field :name do
        pretty_value{ "index[parent_index] #{pretty_value}" }
      end

      pretty_section{ "index[parent_index] #{pretty_section}" }
    end
  end

  class ParentIndexBasePresenter < Admin::Model
    field :name do
      pretty_value{ "base[parent_index_base] #{pretty_value}" }
    end

    base do
      pretty_section{ "base[parent_index_base] #{pretty_section}" }
    end

    index do
      field :name do
        pretty_value{ "index[parent_index_base] #{pretty_value}" }
      end

      pretty_section{ "index[parent_index_base] #{pretty_section}" }
    end
  end

  class ChildPresenter < ParentPresenter
  end

  class ChildParentBasePresenter < ParentBasePresenter
  end

  class ChildParentIndexPresenter < ParentIndexPresenter
  end

  class ChildParentIndexBasePresenter < ParentIndexBasePresenter
  end

  class ChildBasePresenter < ParentPresenter
    field :name do
      pretty_value{ "base[child_base] #{pretty_value}" }
    end

    base do
      pretty_section{ "base[child_base] #{pretty_section}" }
    end
  end

  class ChildBaseParentBasePresenter < ParentBasePresenter
    field :name do
      pretty_value{ "base[child_base]parent_base #{pretty_value}" }
    end

    base do
      pretty_section{ "base[child_base]parent_base #{pretty_section}" }
    end
  end

  class ChildBaseParentIndexPresenter < ParentIndexPresenter
    field :name do
      pretty_value{ "base[child_base]parent_index #{pretty_value}" }
    end

    base do
      pretty_section{ "base[child_base]parent_index #{pretty_section}" }
    end
  end

  class ChildBaseParentIndexBasePresenter < ParentIndexBasePresenter
    field :name do
      pretty_value{ "base[child_base]parent_index_base #{pretty_value}" }
    end

    base do
      pretty_section{ "base[child_base]parent_index_base #{pretty_section}" }
    end
  end

  class ChildIndexPresenter < ParentPresenter
    index do
      field :name do
        pretty_value{ "index[child_index] #{pretty_value}" }
      end

      pretty_section{ "index[child_index] #{pretty_section}" }
    end
  end

  class ChildIndexParentBasePresenter < ParentBasePresenter
    index do
      field :name do
        pretty_value{ "index[child_index]parent_base #{pretty_value}" }
      end

      pretty_section{ "index[child_index]parent_base #{pretty_section}" }
    end
  end

  class ChildIndexParentIndexPresenter < ParentIndexPresenter
    index do
      field :name do
        pretty_value{ "index[child_index]parent_index #{pretty_value}" }
      end

      pretty_section{ "index[child_index]parent_index #{pretty_section}" }
    end
  end

  class ChildIndexParentIndexBasePresenter < ParentIndexBasePresenter
    index do
      field :name do
        pretty_value{ "index[child_index]parent_index_base #{pretty_value}" }
      end

      pretty_section{ "index[child_index]parent_index_base #{pretty_section}" }
    end
  end

  class ChildIndexBasePresenter < ParentPresenter
    field :name do
      pretty_value{ "base[child_index_base] #{pretty_value}" }
    end

    base do
      pretty_section{ "base[child_index_base] #{pretty_section}" }
    end

    index do
      field :name do
        pretty_value{ "index[child_index_base] #{pretty_value}" }
      end

      pretty_section{ "index[child_index_base] #{pretty_section}" }
    end
  end

  class ChildIndexBaseParentBasePresenter < ParentBasePresenter
    field :name do
      pretty_value{ "base[child_index_base]parent_base #{pretty_value}" }
    end

    base do
      pretty_section{ "base[child_index_base]parent_base #{pretty_section}" }
    end

    index do
      field :name do
        pretty_value{ "index[child_index_base]parent_base #{pretty_value}" }
      end

      pretty_section{ "index[child_index_base]parent_base #{pretty_section}" }
    end
  end

  class ChildIndexBaseParentIndexPresenter < ParentIndexPresenter
    field :name do
      pretty_value{ "base[child_index_base]parent_index #{pretty_value}" }
    end

    base do
      pretty_section{ "base[child_index_base]parent_index #{pretty_section}" }
    end

    index do
      field :name do
        pretty_value{ "index[child_index_base]parent_index #{pretty_value}" }
      end

      pretty_section{ "index[child_index_base]parent_index #{pretty_section}" }
    end
  end

  class ChildIndexBaseParentIndexBasePresenter < ParentIndexBasePresenter
    field :name do
      pretty_value{ "base[child_index_base]parent_index_base #{pretty_value}" }
    end

    base do
      pretty_section{ "base[child_index_base]parent_index_base #{pretty_section}" }
    end

    index do
      field :name do
        pretty_value{ "index[child_index_base]parent_index_base #{pretty_value}" }
      end

      pretty_section{ "index[child_index_base]parent_index_base #{pretty_section}" }
    end
  end

  class ChildBaseChildBaseParentBasePresenter < ChildBaseParentBasePresenter
    field :name do
      pretty_value{ "base[child_base][child_base]parent_base #{pretty_value}" }
      pretty_index{ 'index' }
    end

    base do
      pretty_section{ "base[child_base][child_base]parent_base #{pretty_section}" }
    end

    new do
      field :name
    end
  end
end

class ControllerStub
  def memoize(*)
    yield
  end

  def can?(*)
    true
  end

  def action_name
    'index'
  end

  def action
    OpenStruct.new(name: 'index')
  end
end

ActiveSupport.on_load('Admin::Test::ResourceBasePresenter') do
  register_class_option :base_class_new do
    'base_class_new'
  end

  register_option :base_new do
    'base_new'
  end
end

ActiveSupport.on_load('Admin::Test::ResourceMainPresenter') do
  base_class_memoize{ "class_eval #{base_class_memoize}" }
  base_class_accessor{ "class_eval #{base_class_accessor}" }
end
