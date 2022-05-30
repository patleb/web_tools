require 'ext_coffee/turbolinks/redirection'
require 'ext_coffee/turbolinks/assertions'

module Turbolinks
  module Controller
    extend ActiveSupport::Concern

    included do
      include Redirection
    end
  end
end
