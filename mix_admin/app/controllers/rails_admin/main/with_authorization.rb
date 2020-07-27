module RailsAdmin::Main::WithAuthorization
  extend ActiveSupport::Concern

  prepended do
    include Pundit
  end

  # This method is called primarily from the view to determine whether the given user
  # has access to perform the action on a given model. It should return true when authorized.
  # This takes the same arguments as +authorize+. The difference is that this will
  # return a boolean whereas +authorize+ will raise an exception when not authorized.
  def authorized?(action, abstract_model, object = nil)
    model = object || abstract_model&.klass
    policy(model).public_send(action_for_pundit(action)) if action
  end

  # This is called in the new/create actions to determine the initial attributes for new
  # records. It should return a hash of attributes which match what the user
  # is authorized to create.
  def attributes_for(action, abstract_model)
    model = abstract_model&.klass
    policy(model).try(:attributes_for, action) || {}
  end

  # This is called when needing to scope a database query. It is called within the list
  # and bulk_delete/destroy actions and should return a scope which limits the records
  # to those which the user can perform the given action on.
  def policy_scope(abstract_model)
    super(abstract_model.klass)
  end

  def authorized_path_for(action, model, object = nil, key = nil)
    return unless (abstract_model = RailsAdmin::AbstractModel.find(model))
    return unless (action = RailsAdmin.action(action, abstract_model, object))
    if object
      abstract_model.url_for(action.name, id: object.send(key || abstract_model.primary_key))
    else
      abstract_model.url_for(action.name)
    end
  end

  private

  def action_for_pundit(action)
    action[-1, 1] == '?' ? action : "#{action}?"
  end
end
