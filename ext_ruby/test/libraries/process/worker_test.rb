require './test/spec_helper'

class Process::WorkerTest < Minitest::TestCase
  let(:ruby){ Process.worker }
  let(:postgres){ Process.host.workers.find{ |w| w.cmdline == 'postgres'} }

  test '.all, .worker, #snapshot' do
    assert 1 < postgres.children.size
    assert_equal postgres.children, postgres.children.first.pool
    assert_equal [postgres], postgres.children.map(&:parent).uniq(&:pid)

    assert_equal 'ruby', ruby.name
    assert 0 < ruby.ppid
    assert 0.0 < ruby.uptime
    assert Time.current > ruby.start_time
    assert 0.0 < ruby.cpu_usage && ruby.cpu_usage < 1.0
    assert_equal %i(name state ppid nice threads start_time time).sort, ruby.cpu.keys.sort
    assert 0 < ruby.ram_used
    assert 0 == ruby.swap_used
    assert_equal %i(ram_used swap_used total_in total_out).sort, ruby.memory.keys.sort
    assert 0 < ruby.inodes_count
    assert_equal %i(anon dead_device dead_file device epoll file pipe socket).sort, ruby.inodes.keys.sort
    assert Dir.pwd, ruby.cwd
    assert ruby.exe.present?
    assert '', ruby.root.present?
    assert ruby.cmdline.present?
    assert ruby.env.present?

    assert_nil ruby.snapshot
    ruby.snapshot!
    assert_equal (ExtRuby.config.worker_snapshot + [:created_at]).sort, ruby.snapshot.keys.sort
  end
end
