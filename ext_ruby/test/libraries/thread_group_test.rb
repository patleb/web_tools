require './test/spec_helper'

class ThreadGroupTest < Minitest::TestCase
  let!(:values){ Concurrent::Array.new }
  let(:group){ ThreadGroup.new(max_threads: pool_size) }
  let(:pool_size){ 3 }

  context 'with channel' do
    let(:pool_size){ 4 }

    test 'thread_(channel|receive|send|close|siblings), #post, #[]' do
      thread_channel :@data
      names = %w(1st 2nd 3rd)
      names.each do |name|
        group.post(name: name) do
          thread_receive :@data do |value|
            values << [name, value]
          end
        end
      end
      main = group.post(name: 'main') do
        assert_equal names, thread_siblings.map(&:[].with(:name)).sort
        assert_equal '3rd', group['3rd'][:name]
        3.times{ |i| thread_send :@data, i }
        thread_close :@data
        thread_send :@data, 4 do |i|
          values << ['error', i]
        end
      end
      assert_raises ThreadGroup::MaxThreadsReached do
        group.post(name: 'invalid'){}
      end
      assert_equal 0,     group.remaining_threads
      assert_equal false, group.shuttingdown?
      assert_equal true,  group.running?
      assert_equal true,  main.alive? # running or sleeping
      assert_equal false, main.dead?
      group.join_all
      assert_equal true,  main.dead?
      assert_equal true,  main.stop? # dead or sleeping
      assert_equal true,  group.shutdown?
      assert_equal 4,     group.remaining_threads
      assert_equal [0, 1, 2, 4], values.map(&:last).sort
    end
  end

  test 'thread_shuttingdown?, #post_all' do
    data = []
    group.post_all do |i|
      until thread_shuttingdown?
        value = data.pop
        values << [i, value] if value
        Thread.pass
      end
    end
    thread do
      3.times{ |i| data << i }
      Thread.pass until data.empty?
      group.shutdown!
    end
    assert_equal 0,     group.remaining_threads
    assert_equal false, group.shuttingdown?
    assert_equal true,  group.running?
    Thread.pass  until  group.shutdown?
    assert_equal 3,     group.remaining_threads
    assert_equal [0, 1, 2], values.map(&:last).sort
  end

  context 'thread_sleep' do
    test '#kill_all' do
      group.post_all do |i|
        thread_sleep 5 until thread_shuttingdown?
        values << i
      end
      assert_equal 0,     group.remaining_threads
      assert_equal false, group.shuttingdown?
      assert_equal true,  group.running?
      Thread.pass  until  group.list.all?(&:asleep?)
      group.kill_all(0.0001)
      Thread.pass  until  group.shutdown?
      assert_equal 3,     group.remaining_threads
      assert_equal [], values
    end

    test '#timeout' do
      next if ENV['DEBUGGER_HOST']
      group.post_all do |i|
        thread_sleep 5 until thread_shuttingdown?
        values << i
      end
      assert_equal 0,     group.remaining_threads
      assert_equal false, group.shuttingdown?
      assert_equal true,  group.running?
      Thread.pass  until  group.list.all?(&:asleep?)
      group.timeout(0.02) do
        values << 4
      end
      Thread.pass  until  group.shutdown?
      assert_equal 3,     group.remaining_threads
      assert_equal [4], values
    end
  end
end
