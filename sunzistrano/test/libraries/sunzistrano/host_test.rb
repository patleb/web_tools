require './sunzistrano/test/spec_helper'

module Host
  def self.host_file_lines
    @host_file_lines ||= Sunzistrano.root.join('test/fixtures/files/etc/hosts').readlines
  end
end

class HostTest < Minitest::TestCase
  test '.domains' do
    assert_equal({ 'virtual'=> { 'virtual-web.test' => '192.168.65.44' } }, Host.domains)
  end
end
