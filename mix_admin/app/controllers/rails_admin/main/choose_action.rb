module RailsAdmin::Main
  module ChooseAction
    def choose
      section = @model.send(@action.allowed_sections[attributes[:section]])
      attributes = params.require(:main).permit(:section, :label, chosen: [:value, :label], fields: [:field, :calculation])
      attributes.merge!(model: @abstract_model.to_param, prefix: section.choose_prefix)
      notice_name = I18n.t('admin.choose.view')

      if request.post? # CREATE or UPDATE
        @object = RailsAdmin::Choose.new(attributes)
        if @object.save
          redirect_to_on_success notice_name
        else
          handle_save_error :main, notice_name
        end
      elsif request.delete? # DESTROY
        attributes = attributes.slice!(:section, :model, :prefix, :label).with_keyword_access
        if RailsAdmin::Choose.exist? attributes
          RailsAdmin::Choose.delete_by(attributes)
          redirect_to_on_success notice_name, status: :see_other
        else
          redirect_to_back notice: I18n.t('admin.flash.noaction'), status: :see_other
        end
      end
    end
  end
end
