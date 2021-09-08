module LogLines
  class Clamav < LogLine
    json_attribute(
      paths: :json,
    )

    def self.push(log, paths)
      json_data = { paths: paths }
      message = { text: merge_paths(paths), level: :fatal }
      super(log, message: message, json_data: json_data)
    end
  end
end
