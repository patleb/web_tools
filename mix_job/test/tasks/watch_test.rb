require './test/test_helper'
require 'mocha/minitest'
require 'webmock/minitest'
require_relative './watch_mock'

MixJob::Watch.class_eval do
  prepend MixJob::WatchMock
end

Job.class_eval do
  json_attribute :result
end

Minitest.after_run do
  FileUtils.rm_rf(MixJob::Watch::ACTIONS)
  FileUtils.rm_f(MixJob::Watch::REQUESTS)
end

module MixJob
  module ActionTest
    def self.nothing
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
    self.task_name = 'job:watch'
    self.file_fixture_path = Gem.root('mix_job').join('test/fixtures/files').to_s
    self.use_transactional_tests = false

    let(:run_timeout){ 1 }
    let(:options){ {
      listen_timeout: 0.0001,
      poll_interval: 0.001,
      server_interval: 0.0001,
      max_pool_size: 2,
      kill_timeout: run_timeout - 0.2,
      keep_jobs: 10,
    } }
    let(:actions){ good_actions + bad_actions.keys }
    let(:good_actions){[
      'MixJob::ActionTest.nothing',
      'MixJob::ActionTest.args(null, yes, no, on, off, anystring)',
      'MixJob::ActionTest.args 1.0, "c", { a: 2, b: [ 0, nil ] }',
    ]}
    let(:bad_actions){{
      'MixJob::ActionTest.error' => StandardError,
      'MixJob::ActionTest.error(2)' => ArgumentError,
      'MixJob::ActionTest.args({ "a" => 2})' => Psych::SyntaxError,
    }}
    let(:request_missing){ file_fixture('passenger_status.json').read }
    let(:request_present){ request_missing.sub('/users/sign_in', request_dumped) }
    let(:request_dumped){ "/_jobs/SimpleJob/#{SecureRandom.uuid}" }
    let(:status_ok){ status = mock; status.stubs(:success?).returns(true); status }
    let(:status_failed){ status = mock; status.stubs(:success?).returns(false); status }
    let(:server_available){ file_fixture('passenger_status.xml').read }

    before(:all) do
      FileUtils.mkdir_p MixJob::Watch::ACTIONS
    end

    before do
      mock_request(:success)
      mock_request(:server_error).to_return(status: [500, 'Internal Server Error'])
      mock_request(:client_error).to_timeout
      Process::Passenger.any_instance.expects(:passenger_status).with(:xml).at_most(3).returns(
        [server_available, status_ok]
      )
      Process::Passenger.any_instance.expects(:passenger_status).with(:server).at_most(1).returns(
        [request_missing, status_ok]
      )
      FileUtils.rm_f(MixJob::Watch::REQUESTS)
    end

    test '#restore_signals' do
      actions.each do |action|
        Pathname.new("#{MixJob::Watch::ACTIONS}/#{Time.current.to_nanoseconds}.rb").write(action)
      end
      run_rake(goto: 'restore_signals')
    end

    test '#restore_requests' do
      Pathname.new(MixJob::Watch::REQUESTS).write(request_dumped)
      run_rake(goto: 'restore_requests')
    end

    test '#setup_trapping' do
      run_rake(goto: 'setup_trapping')
    end

    test '#setup_signaling' do
      run_rake(goto: 'setup_signaling', **options)
    end

    test '#setup_requesting' do
      Pathname.new(MixJob::Watch::REQUESTS).write(request_dumped)
      Process::Passenger.any_instance.expects(:passenger_status).with(:server).at_least_once.returns(
        [request_present, status_ok],
        [request_missing, status_ok]
      )
      run_rake(goto: 'setup_requesting', **options)
    end

    test '#setup_listening' do
      run_rake(goto: 'setup_listening', **options)
    end

    test '#setup_polling' do
      run_rake(goto: 'setup_polling', skip: 'setup_listening', **options.merge(max_pool_size: 1))
    end

    test '#wait_for_termination' do
      run_rake(goto: 'wait_for_termination', **options.merge(max_pool_size: 1))
    end

    context 'with server error' do
      test '#setup_listening' do
        Process::Passenger.any_instance.expects(:passenger_status).with(:xml).at_least_once.returns(
          ["ERROR: Phusion Passenger doesn't seem to be running.", status_failed],
          [server_available, status_ok]
        )
        run_rake(test: 'not_dequeue_on_error', skip: 'setup_polling,wait_for_termination', **options)
      end
    end

    def mock_request(result)
      stub_request(:post, Regexp.new(Job.url(job_class: '[\w:]+', job_id: '[\w-]+'))).with(
        body: hash_including(job: hash_including(result: result.to_s)),
        headers: { connection: 'Keep-Alive' }
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
