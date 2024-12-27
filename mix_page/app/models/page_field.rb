class PageField < LibMainRecord
  has_userstamps
  has_list

  belongs_to :page
  belongs_to :page_layout, foreign_key: :page_id
  belongs_to :page_template, foreign_key: :page_id
  belongs_to :fieldable, optional: true, polymorphic: true

  accepts_nested_attributes_for :fieldable, update_only: true

  enum! :type, MixPage.config.available_field_types
  enum! :name, MixPage.config.available_field_names, with_keyword_access: true
  enum! :fieldable_type, MixPage.config.available_fieldables

  attr_readonly *%i(
    type
    name
    page_id
  )

  def self.inherited(subclass)
    super
    subclass.send(:default_scope) { rewhere(type: klass.name) } # necessary for superclass usage
  end

  def show?
    fieldable.nil? || fieldable.show?
  end

  def field_label
    field_label_values.compact.uniq.join(' - ')
  end

  def field_label_values
    [self.class.human_attribute_name("name.#{name}", default: name)]
  end

  ### Example for when the association should be on the base class but, in our case, the association is on the children.
  # def fieldable_type=(class_name)
  #    super(class_name.constantize.base_class.to_s)
  # end
end
