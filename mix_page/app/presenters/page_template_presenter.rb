class PageTemplatePresenter < ActionPresenter::Base
  LINK_ICONS = {
    edit:   'fa fa-edit',
    create: 'fa fa-plus-square-o'
  }
  TITLE_OPTIONS = %i(weight only_text)

  def dom_class
    super(object)
  end

  def html_options
    { class: [dom_class] }
  end

  def render(**options)
    options = html_options.with_keyword_access.union!(options)
    if block_given?
      div_(options.except(*TITLE_OPTIONS)) {[
        pretty_title(options.slice(*TITLE_OPTIONS)),
        yield
      ]}
    else
      pretty_title(**options)
    end
  end

  def pretty_title(weight: 4, only_text: false, **options)
    weight = 1 if weight < 1
    weight = 5 if weight > 5
    text = object.title
    with_tag("h#{weight}", **options){[
      span_{ text.presence || pretty_blank },
      (pretty_actions unless only_text),
    ]}
  end

  def pretty_blank
    return '' unless member_actions[:edit]
    I18n.t('page_template.edit', model: object.model_name.human)
  end

  def pretty_actions(tag = :span)
    return '' unless member_actions.any?
    with_tag(tag, '.page_template_actions') do
      member_actions.map do |action, path|
        title = I18n.t("page_template.#{action}", model: object.model_name.human)
        a_(class: "#{action}_#{dom_class}", href: path, title: title) do
          i_(class: LINK_ICONS[action])
        end
      end
    end
  end

  def member_actions
    @member_actions ||= {
      edit:   !Current.user_role? && admin_path_for(:edit, object, _back: true),
      create: !Current.user_role? && admin_path_for(:create, object, _back: true),
    }.reject{ |_, v| v.blank? }
  end
end
