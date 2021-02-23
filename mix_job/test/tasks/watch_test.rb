require './test/rails_helper'
require_relative './watch_mock'

require 'minitest/retry'
Minitest::Retry.use! retry_count: 2

MixJob::Watch.class_eval do
  prepend MixJob::WatchMock
end

Job.class_eval do
  json_attribute :result
end

module MixJob
  module ActionTest
    def self.nothing;
      $task_snapshot.call
    end

    def self.error
      raise StandardError
    end

    def self.args(*args)
      puts args.inspect
    end
  end

  class WatchTest < Rake::TestCase
    self.file_fixture_path = Gem.root('mix_job').join('test/fixtures/files').to_s
    self.use_transactional_tests = false
    self.order_dependent!

    let(:run_timeout){ 1 }
    let(:options){ {
      listen_timeout: 0.01,
      poll_interval: 0.001,
      server_interval: 0.0001,
      max_pool_size: 2,
      keep_jobs: 10,
    } }
    let(:actions){ good_actions + bad_actions.keys }
    let(:good_actions){ [
      'MixJob::ActionTest.nothing',
      'MixJob::ActionTest.args(null, yes, no, on, off, anystring)',
      'MixJob::ActionTest.args 1.0, { a: 2, b: [ 0, nil ] }, "c"',
    ] }
    let(:bad_actions){ {
      'MixJob::ActionTest.error' => StandardError,
      'MixJob::ActionTest.error(2)' => ArgumentError,
      'MixJob::ActionTest.args({ "a" => 2})' => Psych::SyntaxError,
    } }

    before do
      Rails.application.config.force_ssl = true
      mock_request(:success)
      mock_request(:server_error).to_return(status: [500, 'Internal Server Error'])
      mock_request(:client_error).to_timeout
      ActionMailer::Base.deliveries.clear
      [Job, Server, Log, LogLine, LogMessage].each(&:delete_all)
      [MixJob::Watch::ACTIONS].each do |path|
        Pathname.new(path).children.each(&:delete)
      end
    end

    after do
      assert_equal false, Job.exists?
      [Server, Log, LogLine, LogMessage].each(&:delete_all)
      [MixJob::Watch::ACTIONS].each do |path|
        assert_equal 0, Pathname.new(path).children.size
      end
      Rails.application.config.force_ssl = false
    end

    it 'should restore signals' do
      actions.each do |action|
        Pathname.new("#{MixJob::Watch::ACTIONS}/#{Time.current.to_nanoseconds}.rb").write(action)
      end
      run_task(goto: 'restore_signals')
    end

    it 'should setup trapping' do
      run_task(goto: 'setup_trapping')
    end

    it 'should setup signaling' do
      run_task(goto: 'setup_signaling', **options)
    end

    it 'should setup listening' do
      run_task(goto: 'setup_listening', **options)
    end

    it 'should setup polling' do
      status = mock; status.stubs(:success?).returns(true)
      Process::Passenger.any_instance.expects(:passenger_status).at_least_once.returns(
        [file_fixture('passenger_status.xml').read, '', status]
      )
      run_task(goto: 'setup_polling', skip: 'setup_listening', **options.merge(max_pool_size: 1))
    end

    it 'should wait for termination' do
      run_task(goto: 'wait_for_termination', **options.merge(max_pool_size: 1))
    end

    it 'should not dequeue on error' do
      status = mock; status.stubs(:success?).returns(false)
      status_next = mock; status_next.stubs(:success?).at_least_once.returns(true)
      Process::Passenger.any_instance.expects(:passenger_status).at_least_once.returns(
        ['', "ERROR: Phusion Passenger doesn't seem to be running.", status],
        [file_fixture('passenger_status.xml').read, '', status_next]
      )
      run_task(test: 'not_dequeue_on_error', skip: 'setup_polling,wait_for_termination', **options)
    end

    def mock_request(result)
      url = Regexp.new(Job.url(job_class: '[\\w:]+', job_id: '[\\w-]+'))
      stub_request(:post, url).with(
        body: hash_including(job: hash_including(result: result.to_s)),
        headers: { content_type: 'application/json; charset=UTF-8' }
      )
    end

    def job_url(result = nil)
      Job.new(job_data(result)).url(result: result || :success)
    end

    def job_data(result = nil)
      { job_class: 'SimpleJob', job_id: SecureRandom.uuid, result: result || :success}
    end
  end
end
