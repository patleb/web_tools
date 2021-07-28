set :application_variable, "RAILS_APP"
set :output, "#{Whenever.path}/log/cron.log"

Setting.load(env: @environment, app: @application)

deployer = Dir.pwd.match(/home\/(\w+)\//)[1]
rbenv_ruby = "#{Sh.rbenv_export(deployer)}; #{Sh.rbenv_init}"
context = "#{rbenv_ruby}; export RAKE_OUTPUT=true; export RAILS_ENV=#{@environment}; export RAILS_APP=#{@application}"
path = "cd :path &&"
flock = "flock -n #{Whenever.path}/tmp/locks/:task.lock"
rake = "/home/#{deployer}/.rbenv/bin/rbenv sudo bin/rake"
runner = "/home/#{deployer}/.rbenv/bin/rbenv sudo bin/rails runner"

job_type :rake,   "#{context} #{path} #{flock} nice -n 19 #{rake} :task --silent :output"
job_type :rake!,  "#{context} #{path} #{flock} #{rake} :task --silent :output"
job_type :runner, "#{context} #{path} #{flock} nice -n 19 #{runner} ':task' :output"
job_type :runner!, "#{context} #{path} #{flock} #{runner} ':task' :output"
job_type :bash,   "#{context} #{path} #{flock} bash -e -u bin/:task :output"
