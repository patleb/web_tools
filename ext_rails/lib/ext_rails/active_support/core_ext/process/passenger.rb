# frozen_string_literal: true

### References
# https://www.phusionpassenger.com/library/admin/nginx/overall_status_report.html
module Process
  def self.passenger
    @passenger ||= Passenger.new
  end

  class Passenger
    include MemoizedAt

    SERVER = {
      'active_client_count' =>       :active_clients,
      'disconnected_client_count' => :disconnected_clients,
      'peak_active_client_count' =>  :peak_active_clients,
      'pid' =>                       :pid,
      'server_state' =>              :state,
      'total_bytes_consumed' =>      :total_bytes,
      'total_clients_accepted' =>    :total_clients,
      'total_requests_begun' =>      :total_requests,
    }
    CLIENT = {
      'connected_at.local' => :connected_at,
      'connection_state' =>   :state,
      'requests_begun' =>     :requests,
    }
    REQUEST = {
      'flags.https' =>      :https,
      'host' =>             :host,
      'method' =>           :method,
      'path' =>             :path,
      'session.pid' =>      :pid,
      'started_at.local' => :started_at,
      'sticky_session' =>   :sticky_session,
    }
    SERVER_PROCESS_KEYS = ['pid', 'server_state']
    SERVER_THREAD_KEYS = SERVER.keys.except(*SERVER_PROCESS_KEYS).freeze
    SERVER_CLIENT_KEYS = ['active_clients', 'disconnected_clients']

    def clear
      m_clear(:server)
      m_clear(:pool)
    end

    def available?(**)
      pool(**).try(:[], :group_count).to_i > 0
    end

    def requests(**)
      clients(**).try :map do |client|
        client[:request]
      end
    end

    def clients(**)
      server(**).try(:[], :clients)
    end

    def server(**)
      m_access(__method__, **) do
        stdout, status = passenger_status(:server)
        next unless status.success?
        result = ActiveSupport::JSON.decode(stdout) rescue nil
        next unless result
        result.except('threads').values.each_with_object({}.with_indifferent_access) do |thread, process|
          thread.each do |key, value|
            case key
            when *SERVER_PROCESS_KEYS
              process[SERVER[key]] = value
            when *SERVER_THREAD_KEYS
              process[SERVER[key]] ||= 0
              process[SERVER[key]] += value
            when *SERVER_CLIENT_KEYS
              process[:clients] ||= []
              process[:clients] += value.values.map do |client|
                request = client['current_request']
                client = CLIENT.map{ |keys, name| [name, client.dig(*keys.split('.'))] }.to_h
                request = REQUEST.map{ |keys, name| [name, request.dig(*keys.split('.'))] }.to_h
                client[:request] = request
                client
              end
            end
          end
        end
      end
    end

    def pool(**)
      m_access(__method__, **) do
        stdout, status = passenger_status(:xml)
        next unless status.success?
        stdout_with_arrays = stdout.gsub(/<(supergroups|processes)(\/)?>/, '<\1 type="array"\2>')
        result = Hash.from_xml(stdout_with_arrays) rescue nil
        next unless result
        result['info'].with_indifferent_access
      end
    end

    private

    def passenger_status(show)
      cmd = "#{Rails.env.local? ? 'bundle exec' : 'sudo'} passenger-status --show=#{show} --no-header"
      Open3.capture2(cmd)
    end
  end
end
