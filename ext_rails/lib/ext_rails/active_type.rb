MonkeyPatch.add{['active_type', 'lib/active_type.rb', 'cc3f6a21e0b104ef01856bca932e7fc87b608a35f20b4c1c8ab1a674725437fd']}
MonkeyPatch.add{['active_type', 'lib/active_type/virtual_attributes.rb', '61e64a4dc4a8ae361fb3a2d86f636ee4af0bbf7f06e5f97528d8b55aaeb15f48']}

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
