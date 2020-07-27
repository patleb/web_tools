module RailsAdmin::Main
  class BulkPresenter < ActionPresenter::Base[:@abstract_model]
    def form_path
      bulk_action_path(model_name: @abstract_model.to_param)
    end

    def menu
      return if no_menu?
      li_('#bulk_actions.dropdown.pull-right', { title: (wording = t('admin.misc.bulk_menu_title')) }, [
        a_('#js_bulk_menu.dropdown-toggle', { href: '#', data: { toggle: 'dropdown' } }, [
          i_('.fa.fa-check-square-o'),
          span_('.hidden-xs', wording),
          b_('.caret')
        ]),
        ul_('.dropdown-menu') do
          bulkables.map do |action|
            li_ ".bulk_#{action.main_name}" do
              a_ '.js_bulk_link', wording_for(:bulk_link, action), href: '#', data: { action: action.name }
            end
          end
        end
      ])
    end

    def no_menu?
      !trash_action? && (!index_section.checkboxes? || bulkables.empty?)
    end

    private

    def bulkables
      @_bulkables ||= RailsAdmin.actions(bulkable_type, @abstract_model)
    end

    def bulkable_type
      trash_action? ? :bulkable_trash : :bulkable
    end
  end
end
