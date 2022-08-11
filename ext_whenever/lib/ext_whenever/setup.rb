set :application_variable, "RAILS_APP"
set :output, "#{Whenever.path}/log/cron.log"

Setting.load(env: @environment, app: @application)

rbenv_sudo = "rbenv sudo RAKE_OUTPUT=true :environment_variable=:environment :application_variable=:application"
context    = "export BASH_OUTPUT=true; export RAKE_OUTPUT=true; export :environment_variable=:environment; :application_variable=:application;"
path       = "cd :path;"
flock      = "flock -n #{Whenever.path}/tmp/locks/:task.lock"
rake       = "#{rbenv_sudo} bin/rake"
bash       = "bash -e -u +H #{Sunzistrano::BASH_DIR}/scripts"
helper     = "export helper=':task';"

job_type :rake,         "#{Sh.rbenv_ruby} #{path} #{flock} nice -n 19 #{rake} ':task' --silent :output"
job_type :rake!,        "#{Sh.rbenv_ruby} #{path} #{flock} #{rake} ':task' --silent :output"
job_type :bash_script,  "#{Sh.rbenv_ruby} #{path} #{context} #{flock} nice -n 19 #{bash}/:task.sh :output"
job_type :bash_script!, "#{Sh.rbenv_ruby} #{path} #{context} #{flock} #{bash}/:task.sh :output"
job_type :bash_helper,  "#{Sh.rbenv_ruby} #{path} #{context} #{helper} #{flock} nice -n 19 #{bash}/helper.sh :output"
job_type :bash_helper!, "#{Sh.rbenv_ruby} #{path} #{context} #{helper} #{flock} #{bash}/helper.sh :output"
