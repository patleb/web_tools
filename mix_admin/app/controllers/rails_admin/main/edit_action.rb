# TODO use variants
# https://api.rubyonrails.org/classes/ActionController/MimeResponds.html
# http://blog.wilcoxd.com/2011/05/12/returning-html-content-from-ajax-requests-a-pattern-for-rails-3/
module RailsAdmin::Main
  module EditAction
    def edit
      if request.get? # EDIT
        respond_to do |format|
          format.html.modal { render :edit, layout: false }
          format.html.none  { render :edit }
        end
      elsif request.put? # UPDATE
        sanitize_params_for!(request.variant.modal? ? :modal : :update)

        attributes = params[@abstract_model.param_key]
        @object.assign_attributes(attributes) if attributes
        attributes_for(:update, @abstract_model).each do |name, value|
          @object.send("#{name}=", value)
        end

        if @object.save
          respond_to do |format|
            format.html { redirect_to_on_success }
            format.json.inline do
              field_name, _field_value = attributes.to_h.first
              # TODO use @model.update or similar
              field = @model.index.with(object: @object).visible_fields.find do |f|
                f.inline_update? && f.name == field_name.to_sym
              end
              render json: { value: field.value, text: field.pretty_value_or_blank, flash: { success: success_notice } }
            end
            format.json.modal do
              render json: { value: @object.id.to_s, text: @model.with(object: @object).object_label }
            end
          end
        else
          handle_save_error :edit
        end
      end
    end
  end
end
