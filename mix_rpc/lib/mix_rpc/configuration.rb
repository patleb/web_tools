module MixRpc
  has_config do
    attr_writer :yml_path
    attr_writer :sql_path

    def yml_path
      @yml_path ||= Rails.root.join('db/rpc.yml')
    end

    def sql_path
      @sql_path ||= Rails.root.join('db/structure.sql')
    end
  end
end
