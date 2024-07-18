# frozen_string_literal: true

module Rpc
  class Function < VirtualRecord::Base
    RPC_FUNCTION = 'CREATE FUNCTION rpc.'
    RPC_RETURNS  = /\) RETURNS .+$/
    RPC_DEFAULT  = / DEFAULT (ARRAY\[[^\]]+\]|[^,]+)/
    PG_EXCEPTION = /^PG::\w+: /
    STATEMENT    = /LINE \d+:/
    HINT_MARKER  = / \^/

    attribute :schema, default: 'rpc'
    attribute :args, :array
    attribute :params, :hash
    attribute :result, :hash

    alias_method :call!, :update!

    validate :call

    def self.call!(schema: 'rpc', id:, args:, params: {})
      function = new(schema: schema, id: id, args: args)
      function.ivar(:@new_record, false)
      function.call! params: params
      function.result
    end

    def self.list
      return [] unless MixRpc.config.yml_path.exist?

      @all ||= (YAML.safe_load(MixRpc.config.yml_path.read, [Symbol]) || {}).each_with_object([]) do |(id, args), memo|
        memo << { id: id, args: args }
      end
    end

    def self.to_yaml
      parse_schema.to_yaml(line_width: -1).delete_prefix("---\n").delete_prefix("--- {}\n")
    end

    def self.parse_schema
      File.readlines(MixRpc.config.sql_path, chomp: true).each_with_object({}) do |line, memo|
        next unless line.start_with? RPC_FUNCTION
        name, args = line.delete_prefix(RPC_FUNCTION).sub(RPC_RETURNS, '').split('(', 2)
        args = args.gsub(RPC_DEFAULT, '').split(', ').map(&:split.with(' ', 2)).map do |(arg, type)|
          { name: arg, hash: type.match?(/^jsonb?$/), array: type.end_with?('[]') }.select{ |_, v| v }
        end
        (memo[name] ||= Set.new).merge(args)
      end.transform_values(&:to_a)
    end

    def self.error_hash(message)
      message = message.split('ERROR: ', 2).last
      message, hint = message.split(' HINT: ', 2)
      error, statement = message.split(' STATEMENT: ', 2)
      { error: error, statement: statement, hint: hint }.compact
    end

    def error_hash
      self.class.error_hash(error_message)
    end

    def error_message
      errors.full_messages.first
    end

    def call
      permit = true
      values = args.select_map do |arg|
        name = arg[:name]
        next permit = false unless permit && params.has_key?(name)
        case
        when arg[:array] then "ARRAY[#{params[name].map{ |item| quote(item) }.join(',')}]"
        when arg[:hash]  then quote(params[name].to_json)
        else quote(params[name])
        end
      end
      self.result = select_function("SELECT #{schema}.#{id}(#{values.join(',')})")
    rescue ActiveRecord::StatementInvalid => e
      errors.add :base, e.message.squish.sub(PG_EXCEPTION, '').sub(STATEMENT, 'STATEMENT:').sub(HINT_MARKER, '')
    end

    private

    def select_function(sql)
      self.class.ar_connection.select_value(self.class.sanitize_sql(sql), "#{self.class.name} Call")
    end

    def quote(value)
      self.class.ar_connection.quote(value)
    end
  end
end
