module RailsAdmin::Main
  module NewAction
    def new
      if request.get? # NEW
        @object = @abstract_model.new
        attributes_for(:new, @abstract_model).each do |name, value|
          @object.send("#{name}=", value)
        end
        if (object_params = params[@abstract_model.param_key])
          sanitize_params_for!(request.variant.modal? ? :modal : :create)
          @object.assign_attributes(@object.attributes.merge(object_params.to_h))
        end
        respond_to do |format|
          format.html.modal { render :new, layout: false }
          format.html.none  { render :new }
        end
      elsif request.post? # CREATE
        @modified_assoc = []
        @object = @abstract_model.new
        sanitize_params_for!(request.variant.modal? ? :modal : :create)

        attributes = params[@abstract_model.param_key]
        @object.assign_attributes(attributes) if attributes
        attributes_for(:create, @abstract_model).each do |name, value|
          @object.send("#{name}=", value)
        end

        if @object.save
          respond_to do |format|
            format.html { redirect_to_on_success }
            format.json do
              render json: { value: @object.id.to_s, text: @model.with(object: @object).object_label }
            end
          end
        else
          handle_save_error :new
        end
      end
    end
  end
end
