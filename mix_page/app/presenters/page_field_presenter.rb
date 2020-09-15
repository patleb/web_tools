class PageFieldPresenter < ActionPresenter::Base[:@page, :@virtual_path]
  attr_accessor :list

  def render
    h_(
      div_('.show_object') do
        yield
      end,
      ul_('.member_actions', if: member_actions.any?) do
        member_actions.map do |action, path|
          li_(".#{action}_object") do
            a_(href: path){ action.to_s.humanize }
          end
        end
      end
    )
  end

  def dom_class
    [super(object), super(object.class.base_class)].uniq
  end

  def member_actions
    @member_actions ||= {
      edit:   admin_path_for(:edit, object, _back: true),
      delete: admin_path_for(:delete, object, _back: true),
    }.compact
  end
end
