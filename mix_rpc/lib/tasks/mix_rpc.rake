namespace :rpc do
  namespace :schema do
    desc 'dump rpc schema'
    task dump: :environment do
      File.write(Rpc::Function.yml_path, Rpc::Function.to_yaml)
    end
  end
end
Rake::Task['db:structure:dump'].enhance ['rpc:schema:dump']
