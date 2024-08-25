require_dir __FILE__, 'metal', reverse: true

ActionController::API.class_eval do
  class_attribute :local

  include ActiveSupport::LazyLoadHooks::Autorun
  include ActionController::MimeResponds
  include ActionController::Redirecting::WithStringUrl
  include ActionController::WithContext
  include ActionController::WithMemoization

  def self.inherited(subclass)
    super
    if subclass.superclass == ActionController::API
      subclass.include ActionController::WithStatus
    end
    subclass.include ActionController::WithErrors
  end

  ActiveSupport.run_load_hooks('ActionController', self, parent: true)
end
