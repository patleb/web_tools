require './test/test_helper'
require './mix_admin/test/support/model_context'

class Admin::ModelTest < ActiveSupport::TestCase
  fixtures 'test/records'

  let(:resource_presenter){ resource.admin_presenter }
  let(:resource_model){ resource.admin_model }
  let(:resource){ Test::Resource.new(id: 'resource') }
  let(:sibling_presenter){ sibling.admin_presenter }
  let(:sibling_model){ sibling.admin_model }
  let(:sibling){ Test::ResourceSibling.new(id: 'sibling') }
  let(:record_presenter){ record.admin_presenter }
  let(:record_model){ record.admin_model }
  let(:record){ ActiveType.cast(test_records(:test_record_1), Test::Extensions::RecordExtension) }

  test '.admin_model, .section, .group, .field' do
    assert_equal resource, resource_presenter.record
    assert_equal Admin::Test::ResourcePresenter, resource_model
    assert_equal Admin::Test::ResourceMainPresenter, resource_model.superclass

    assert_equal [:base, :index], resource_model.sections.keys.sort
    assert_equal [
        Admin::Test::ResourcePresenter::BaseSection,
        Admin::Test::ResourcePresenter::IndexSection
      ], resource_model.sections.values.map(&:class)

    assert_equal [:default, :main, :default], resource_model.groups.values.flat_map(&:keys)
    assert_equal [0, 1, 0], resource_model.groups.values.flat_map(&:values).map(&:weight)
    assert_equal [
        Admin::Test::ResourcePresenter::BaseSection::DefaultGroup,
        Admin::Test::ResourcePresenter::BaseSection::MainGroup,
        Admin::Test::ResourcePresenter::IndexSection::DefaultGroup
      ], resource_model.groups.values.flat_map(&:values).map(&:class)

    assert_equal [:base_name, :main_name, :base_name], resource_model.fields.values.flat_map(&:keys)
    assert_equal [0, 1, 0], resource_model.fields.values.flat_map(&:values).map(&:weight)
    assert_equal [
        Admin::Test::ResourcePresenter::BaseSection::BaseNameField,
        Admin::Test::ResourcePresenter::BaseSection::MainNameField,
        Admin::Test::ResourcePresenter::IndexSection::BaseNameField
      ], resource_model.fields.values.flat_map(&:values).map(&:class)
  end

  test '.register_option' do
    sibling_presenter.instance_eval do
      base_option{ "sibling #{base_option}"}
      main_locale{ "sibling #{main_locale}_#{main_locale?}" }
    end

    assert_equal 'class_eval base_class_memoize', sibling_model.base_class_memoize
    assert_equal sibling_model.base_class_memoize.object_id, sibling_model.base_class_memoize.object_id

    assert_equal 'sibling class_eval main base_class_accessor', sibling_model.base_class_accessor
    assert_equal 'sibling class_eval main base_class_accessor', sibling_presenter.base_class_accessor

    assert_equal 'main base_class_option', sibling_model.base_class_option

    assert_equal 'sibling base_option', sibling_presenter.base_option

    assert_equal 'sibling main_class_memoize', sibling_model.main_class_memoize
    refute_equal sibling_model.main_class_memoize.object_id, sibling_model.main_class_memoize.object_id

    assert_equal "sibling main_locale_#{I18n.locale}_true", sibling_presenter.main_locale
    assert_equal sibling_presenter.main_locale.object_id, sibling_presenter.main_locale.object_id
    refute_equal sibling_presenter.main_locale.object_id, sibling_presenter.main_locale(memoize: false).object_id

    assert_equal 'sibling_option', sibling_presenter.sibling_option

    assert_equal 'base_class_new', sibling_model.base_class_new
    assert_equal 'base_new', sibling_presenter.base_new
  end

  test '#with' do
    clone = resource_presenter.with(var: 'var')
    assert_equal 'var', clone.var
    assert_equal resource_presenter.ivar(:@values).object_id, clone.ivar(:@values).object_id
    assert_equal resource_presenter.ivar(:@memoized).object_id, clone.ivar(:@memoized).object_id
    refute_equal resource_presenter, clone
  end

  test '.columns' do
    assert record_model.columns.any?(&:is_a?.with(Admin::Model::Column))
    assert record_model.columns.any?(&:is_a?.with(Admin::Model::VirtualColumn))
    assert record_model.columns.any?(&:is_a?.with(Admin::Model::Attribute))
  end

  test 'field inheritance' do
    Current.controller = ControllerStub.new
    results = [
      #   base section                     index section
      [ ['child',                         'child'],                     # base fields added without proc
        ['base[parent_base] child',       'base[parent_base] child'],   # only base fields defined
        [nil,                             'index[parent_index] child'], # no base fields defined
        ['base[parent_index_base] child', 'index[parent_index_base] base[parent_index_base] child'],
      ],
      [ ['base[child_base] child',                                          'base[child_base] child'],
        ['base[child_base]parent_base base[parent_base] child',             'base[child_base]parent_base base[parent_base] child'],
        ['base[child_base]parent_index child',                              'index[parent_index] child'],
        ['base[child_base]parent_index_base base[parent_index_base] child', 'index[parent_index_base] base[parent_index_base] child'],
      ],
      [ ['child',                         'index[child_index] child'],
        ['base[parent_base] child',       'index[child_index]parent_base base[parent_base] child'],
        [nil,                             'index[child_index]parent_index index[parent_index] child'],
        ['base[parent_index_base] child', 'index[child_index]parent_index_base base[parent_index_base] child'],
      ],
      [ ['base[child_index_base] child',                                          'index[child_index_base] base[child_index_base] child'],
        ['base[child_index_base]parent_base base[parent_base] child',             'index[child_index_base]parent_base base[child_index_base]parent_base base[parent_base] child'],
        ['base[child_index_base]parent_index child',                              'index[child_index_base]parent_index base[child_index_base]parent_index child'],
        ['base[child_index_base]parent_index_base base[parent_index_base] child', 'index[child_index_base]parent_index_base base[child_index_base]parent_index_base base[parent_index_base] child'],
      ],
    ]
    ['Child', 'ChildBase', 'ChildIndex', 'ChildIndexBase'].each_with_index do |child_type, child_i|
      ['', 'ParentBase', 'ParentIndex', 'ParentIndexBase'].each_with_index do |parent_type, parent_i|
        child_class = Test.const_get("#{child_type}#{parent_type}")
        child = child_class.new(id: 'child').admin_presenter
        %i(base index).each_with_index do |section_name, section_i|
          pretty_value = results[child_i][parent_i][section_i]
          section = child.admin_model.section(section_name).with(presenter: child)
          field = section.fields_hash[:name]
          assert_equal pretty_value, field&.pretty_value, "#{child_class.name}[#{child_i}][#{parent_i}][#{section_name}]"
        end
      end
    end
    pretty_value = 'base[child_base][child_base]parent_base base[child_base]parent_base base[parent_base] child'
    child = Test::ChildBaseChildBaseParentBase.new(id: 'child').admin_presenter
    section = child.admin_model.section(:base).with(presenter: child)
    field = section.fields_hash[:name]
    assert_equal pretty_value, field.pretty_value
  end

  test 'section inheritance' do
    Current.controller = ControllerStub.new
    results = [
      #   base section                    index section
      [ ['base',                         'index'],
        ['base[parent_base] base',       'base[parent_base] base'],
        ['base',                         'index[parent_index] index'],
        ['base[parent_index_base] base', 'index[parent_index_base] base[parent_index_base] base'],
      ],
      [ ['base[child_base] base',                                          'base[child_base] base'],
        ['base[child_base]parent_base base[parent_base] base',             'base[child_base]parent_base base[parent_base] base'],
        ['base[child_base]parent_index base',                              'index[parent_index] index'],
        ['base[child_base]parent_index_base base[parent_index_base] base', 'index[parent_index_base] base[parent_index_base] base'],
      ],
      [ ['base',                         'index[child_index] index'],
        ['base[parent_base] base',       'index[child_index]parent_base base[parent_base] base'],
        ['base',                         'index[child_index]parent_index index[parent_index] index'],
        ['base[parent_index_base] base', 'index[child_index]parent_index_base base[parent_index_base] base'],
      ],
      [ ['base[child_index_base] base',                                          'index[child_index_base] base[child_index_base] base'],
        ['base[child_index_base]parent_base base[parent_base] base',             'index[child_index_base]parent_base base[child_index_base]parent_base base[parent_base] base'],
        ['base[child_index_base]parent_index base',                              'index[child_index_base]parent_index base[child_index_base]parent_index base'],
        ['base[child_index_base]parent_index_base base[parent_index_base] base', 'index[child_index_base]parent_index_base base[child_index_base]parent_index_base base[parent_index_base] base'],
      ],
    ]
    ['Child', 'ChildBase', 'ChildIndex', 'ChildIndexBase'].each_with_index do |child_type, child_i|
      ['', 'ParentBase', 'ParentIndex', 'ParentIndexBase'].each_with_index do |parent_type, parent_i|
        child_class = Test.const_get("#{child_type}#{parent_type}")
        child = child_class.new(id: 'child').admin_presenter
        %i(base index).each_with_index do |section_name, section_i|
          pretty_section = results[child_i][parent_i][section_i]
          section = child.admin_model.section(section_name)
          assert_equal pretty_section, section.pretty_section, "#{child_class.name}[#{child_i}][#{parent_i}][#{section_name}]"
        end
      end
    end
    pretty_section = 'base[child_base][child_base]parent_base base[child_base]parent_base base[parent_base] base'
    child = Test::ChildBaseChildBaseParentBase.new(id: 'child').admin_presenter
    section = child.admin_model.section(:base)
    assert_equal pretty_section, section.pretty_section
  end
end
