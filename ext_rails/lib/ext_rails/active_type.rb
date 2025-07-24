MonkeyPatch.add{['active_type', 'lib/active_type.rb', '1a08a075c65424c5e5a2356556704e21a8df2c2e448fc8f873235f21709d3cbc']}
MonkeyPatch.add{['active_type', 'lib/active_type/virtual_attributes.rb', '454f864344ea7c6763c44b1860affceec48c5d0c7a6714752e556fdbc195a3f0']}

require 'active_type/version'
require 'active_type/object'
require 'active_type/record'
require 'active_type/util'

module ActiveType
  extend Util

  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new
  end
end

require_dir __FILE__, 'active_type', reverse: true
