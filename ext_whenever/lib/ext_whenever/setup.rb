set :application_variable, "RAILS_APP"
set :output, "#{Whenever.path}/log/cron.log"

Setting.load(env: @environment, app: @application)

rbenv_sudo = <<-SH.squish
  rbenv sudo
  PACK=false
  RAKE_OUTPUT=true
  :environment_variable=:environment
  :application_variable=:application
SH
context = <<-SH.squish
  export BASH_OUTPUT=cron;
  export :environment_variable=:environment;
  export :application_variable=:application;
SH
path      = "cd :path &&"
flock     = "flock -n #{Whenever.path}/tmp/locks/:task.lock"
rake      = "#{rbenv_sudo} bin/rake"
mutex     = "flock -w 60 #{Whenever.path}/tmp/locks/bash.lock -c"
bash      = "bash -e -u +H #{Sunzistrano::BASH_DIR}/scripts"
helper    = "export helper=:task &&"
no_helper = "&& unset helper"

job_type :rake,    "#{Sh.rbenv_ruby} #{path} #{flock} nice -n 19 #{rake} ':task' --silent :output"
job_type :rake!,   "#{Sh.rbenv_ruby} #{path} #{flock} #{rake} ':task' --silent :output"
job_type :script,  "#{Sh.rbenv_ruby} #{context} #{path} #{mutex} '#{flock} nice -n 19 #{bash}/:task.sh :output'"
job_type :script!, "#{Sh.rbenv_ruby} #{context} #{path} #{mutex} '#{flock} #{bash}/:task.sh :output'"
job_type :helper,  "#{Sh.rbenv_ruby} #{context} #{path} #{mutex} '#{helper} #{flock} nice -n 19 #{bash}/helper.sh :output #{no_helper}'"
job_type :helper!, "#{Sh.rbenv_ruby} #{context} #{path} #{mutex} '#{helper} #{flock} #{bash}/helper.sh :output #{no_helper}'"
