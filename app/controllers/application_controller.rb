class ApplicationController < ActionController::Base
  include MixTemplate::WithPjax
  include MixTemplate::WithLayoutValues
end
