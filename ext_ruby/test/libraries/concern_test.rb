require './test/spec_helper'

class ParentClass
  def self.overridden(*callers)
    callers << 'Parent'
  end

  def overridden(*callers)
    callers << 'Parent'
  end

  def redefined(*callers)
    callers << 'Parent'
  end
end

module ExtendModule
  def overridden(*callers)
    super(*callers << 'Extend')
  end
end

module IncludeModule
  extend ActiveSupport::Concern

  included do
    alias_method :not_included_method, :redefined
    define_method :redefined do |*callers|
      not_included_method(*callers << 'Included')
    end
  end

  class_methods do
    def overridden(*callers)
      super(*callers << 'Include')
    end
  end

  def overridden(*callers)
    super(*callers << 'Include')
  end
end

module PrependModule
  extend ActiveSupport::Concern

  prepended do
    alias_method :not_prepended_method, :redefined
    define_method :redefined do |*callers|
      not_prepended_method(*callers << 'Prepended')
    end
  end

  class_methods do
    def overridden(*callers)
      super(*callers << 'Prepend')
    end
  end

  def overridden(*callers)
    super(*callers << 'Prepend')
  end
end

class PrependableTest < Minitest::TestCase
  let(:overridden_class){ BaseClass.overridden }
  let(:overridden_instance){ BaseClass.new.overridden }
  let(:redefined){ BaseClass.new.redefined }

  before do
    class Object::BaseClass < ParentClass
      def self.overridden(*callers)
        super(*callers << 'Base')
      end

      def overridden(*callers)
        super(*callers << 'Base')
      end

      def redefined(*callers)
        super(*callers << 'Base')
      end
    end
  end

  after do
    Object.send :remove_const, :BaseClass
  end

  context '.extend, .include, .prepend' do
    before do
      Object::BaseClass.class_eval do
        extend ExtendModule
        include IncludeModule
        prepend PrependModule
      end
    end

    test do
      assert_equal ["Prepend", "Base", "Include", "Extend", "Parent"], overridden_class
      assert_equal ["Prepend", "Base", "Include", "Parent"], overridden_instance
    end
  end

  context '.prepend, .include, .extend' do
    before do
      Object::BaseClass.class_eval do
        include IncludeModule
        extend ExtendModule
        prepend PrependModule
      end
    end

    test do
      assert_equal ["Prepend", "Base", "Extend", "Include", "Parent"], overridden_class
      assert_equal ["Prepend", "Base", "Include", "Parent"], overridden_instance
    end
  end

  context '.included, .prepended' do
    before do
      Object::BaseClass.class_eval do
        include IncludeModule
        prepend PrependModule
      end
    end

    test do
      assert_equal ["Prepended", "Included", "Base", "Parent"], redefined
    end
  end

  context '.prepended, .included' do
    before do
      Object::BaseClass.class_eval do
        prepend PrependModule
        include IncludeModule
      end
    end

    test do
      assert_equal ["Included", "Prepended", "Base", "Parent"], redefined
    end
  end
end
