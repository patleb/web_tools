class PageTemplatePresenter < ActionPresenter::Base
  def dom_class
    super(object)
  end

  def html_options
    { class: [dom_class] }
  end

  def render(weight: 4, **options)
    weight = 1 if weight < 1
    weight = 5 if weight > 5
    options = html_options.with_keyword_access.union!(options)
    if block_given?
      div_(options) {[
        pretty_title(weight),
        yield
      ]}
    else
      pretty_title(weight, options)
    end
  end

  def pretty_title(weight, **options)
    text = object.title
    with_tag("h#{weight}", **options){[
      span_{ text.presence || pretty_blank },
      a_(class: "edit_#{dom_class}", href: edit_action, if: edit_action){ i_('.fa.fa-edit') },
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
