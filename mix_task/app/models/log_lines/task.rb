module LogLines
  class Task < LogLine
    json_attribute(
      name: :string,
      args: :json,
      time: :float,
      ram: :big_integer,
    )

    scope :ssl_create_or_renew, -> { where(name: 'certificate:lets_encrypt:create_or_renew') }

    def self.ssl_upgrade?(time)
      ssl_create_or_renew.where(created_at: (time - 1.minute)..time).exists?
    end

    def self.push(log, name, args: nil, time: nil)
      json_data = { name: name, args: args, time: time, ram: Process.worker.ram_used }
      message = { text: [name, args&.pretty_hash!].join!(' '), level: :info }
      super(log, message: message, json_data: json_data)
    end
  end
end
