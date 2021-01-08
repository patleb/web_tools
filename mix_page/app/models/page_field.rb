class PageField < LibRecord
  self.skip_locking_attributes += ['parent_id']

  has_userstamp
  has_list

  belongs_to :page, -> { with_discarded }
  belongs_to :page_layout, -> { with_discarded }, foreign_key: :page_id
  belongs_to :page_template, -> { with_discarded }, foreign_key: :page_id
  belongs_to :fieldable, -> { with_discarded }, optional: true, polymorphic: true
  belongs_to :parent, -> { with_discarded }, list_parent: self

  enum type: MixPage.config.available_field_types
  enum name: MixPage.config.available_field_names
  enum fieldable_type: MixPage.config.available_fieldables

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
    super && (fieldable.nil? || fieldable.show?)
  end

  def rails_admin_object_label
    rails_admin_object_label_values.compact.uniq.join(' - ')
  end

  def rails_admin_object_label_values
    [page_template&.title, self.class.human_attribute_name("name.#{name}", default: name)]
  end

  ### Example for when the association should be on the base class but, in our case, the association is on the children.
  # def fieldable_type=(class_name)
  #    super(class_name.constantize.base_class.to_s)
  # end
end
