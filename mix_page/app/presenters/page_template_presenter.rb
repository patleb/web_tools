class PageTemplatePresenter < ActionPresenter::Base
  def render(weight: 4, **options)
    weight = 1 if weight < 1
    weight = 5 if weight > 5
    text = object.title
    css_class = dom_class(object)
    with_tag("h#{weight}", { class: [css_class] }.with_keyword_access.union!(options)){[
      span_{ text.presence || pretty_blank },
      a_(class: "edit_#{css_class}", href: edit_action, if: edit_action){ i_('.fa.fa-edit') },
    ]}
  end

  def pretty_blank
    I18n.t('page_fields.edit', model: object.model_name.human.downcase)
  end

  def edit_action
    return @edit_action if defined? @edit_action
    @edit_action = !Current.user_role? && admin_path_for(:edit, object, _back: true)
  end
end
