require './test/spec_helper'

class Process::HostTest < Minitest::TestCase
  let(:host){ Process.host }

  test '.host, #snapshot' do
    assert_match /[\w-]/, host.name
    assert_match /[a-f0-9]+/, host.machine_id
    assert_match /(\d{1,3}\.){3}\d{1,3}/, host.private_ip
    assert 0 < host.uptime
    assert Time.current > host.boot_time
    assert_equal Etc.nprocessors, host.cpu_count
    assert 0 < host.cpu_pids
    assert 0.0 < host.cpu_usage && host.cpu_usage < 1.0
    assert 0.0 < host.cpu_total
    assert 0.0 < (cpu_work = host.cpu_work)
    assert 0.0 < (cpu_idle = host.cpu_idle)
    assert 0.0 <= (cpu_steal = host.cpu_steal)
    host.cpu_load.each{ |load| assert 0.0 < load }
    assert_equal %i(size user nice system idle iowait irq softirq steal boot pids).sort, host.cpu.keys.sort
    assert 0.0 <= host.ram_usage && host.ram_usage < 1.0
    assert 0.0 < host.ram_total
    assert 0.0 < host.ram_used
    assert 0.0 <= host.swap_usage && host.swap_usage < 1.0
    assert 0.0 < host.swap_total
    assert 0.0 < host.swap_used
    assert_equal %i(ram_in ram_out ram_total ram_used swap_in swap_out swap_total swap_used).sort, host.memory.keys.sort
    if true # ENV['CI'].present?
      host.disks_inodes.each_value{ |inodes| assert 0 < inodes }
      host.disks.each_value do |values|
        assert_equal %i(fs_total fs_used io_size io_time).sort, values.keys.sort
        values.each_value do |value|
          Array.wrap(value).each{ |size| assert 0 < size }
        end
      end
      assert host.mounts.present?
    end
    host.network_usage.each{ |usage| assert 0 < usage } # [in, out]
    assert_equal host.network_usage, host.network
    assert 1 < host.networks.size
    assert host.sockets.present?
    assert host.sockets(pid: false).present?
    assert host.sockets(worker: true).present?
    assert_equal 6, host.sockets.first.dig(1, 0).size
    assert 0 < host.pids.size
    assert host.inodes.present?
    assert 0 < host.pagesize
    assert 0 < host.hertz

    assert_nil host.snapshot
    host.snapshot!
    assert_equal (ExtRuby.config.host_snapshot + [:created_at]).sort, host.snapshot.keys.sort

    host.network_usage.each{ |usage| assert_equal 0, usage }
    host.network.each_with_index{ |size, i| assert size > host.network_usage[i] }
    assert cpu_work > host.cpu_work
    assert cpu_idle > host.cpu_idle
    assert cpu_steal >= host.cpu_steal
  end
end
