namespace :rpc do
  namespace :schema do
    desc 'dump rpc schema'
    task dump: :environment do
      File.write(MixRpc.config.yml_path, Rpc::Function.to_yaml)
    end
  end
end
Rake::Task['db:_dump'].enhance ['rpc:schema:dump']
