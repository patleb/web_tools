Setting.load(env: @environment)

deployer = Dir.pwd.match(/home\/(\w+)\//)[1]
rbenv_ruby = %{export PATH="/home/#{deployer}/.rbenv/bin:/home/#{deployer}/.rbenv/plugins/ruby-build/bin:$PATH"; eval "$(rbenv init -)"}
context = %{export RAKE_OUTPUT=true; #{rbenv_ruby}; cd :path && :environment_variable=:environment}
flock_cmd = %{flock -n #{Whenever.path}/tmp/locks/:task.lock}

set :output, "#{Whenever.path}/log/cron.log"
job_type :rake, "#{context} #{flock_cmd} nice -n 19 :bundle_command rake :task --silent :output"
job_type :bash, "#{context} #{flock_cmd} bash -e -u bin/:task :output"
