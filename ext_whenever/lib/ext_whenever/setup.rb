set :application_variable, "RAILS_APP"
set :output, "#{Whenever.path}/log/cron.log"

Setting.load(env: @environment, app: @application)

rbenv_ruby = "#{Sh.rbenv_export}; #{Sh.rbenv_init};"
rbenv_sudo = "/home/deployer/.rbenv/bin/rbenv sudo RAKE_OUTPUT=true :environment_variable=:environment :application_variable=:application"
context    = "export RAKE_OUTPUT=true; export :environment_variable=:environment; :application_variable=:application;"
path       = "cd :path &&"
flock      = "flock -n #{Whenever.path}/tmp/locks/:task.lock"
rake       = "#{rbenv_sudo} bin/rake"
bash       = "bash -e -u #{Sunzistrano::BASH_DIR}/scripts"
helper     = "export helper=':task';"

job_type :rake,         "#{rbenv_ruby} #{path} #{flock} nice -n 19 #{rake} ':task' --silent :output"
job_type :rake!,        "#{rbenv_ruby} #{path} #{flock} #{rake} ':task' --silent :output"
job_type :bash,         "#{rbenv_ruby} #{context} #{path} #{flock} nice -n 19 #{bash}/:task.sh :output"
job_type :bash!,        "#{rbenv_ruby} #{context} #{path} #{flock} #{bash}/:task.sh :output"
job_type :bash_helper,  "#{rbenv_ruby} #{context} #{helper} #{path} #{flock} nice -n 19 #{bash}/helper.sh :output"
job_type :bash_helper!, "#{rbenv_ruby} #{context} #{helper} #{path} #{flock} #{bash}/helper.sh :output"
