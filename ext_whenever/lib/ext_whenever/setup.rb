set :application_variable, "RAILS_APP"
set :output, "#{Whenever.path}/log/cron.log"
set :with, nil

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
rake_task = "#{rbenv_sudo} bin/rake ':task'"
mutex     = "flock -w 60 #{Whenever.path}/tmp/locks/bash.lock -c"
bash_task = "bash -e -u +H #{Sunzistrano::BASH_DIR}/scripts/$([[ :task == *.* ]] && echo helper || echo :task).sh :with"
helper    = "export helper=:task &&"
no_helper = "&& unset helper"

job_type :rake,   "#{Sh.rbenv_ruby} #{path} #{flock} nice -n 19 #{rake_task} --silent :output"
job_type :rake!,  "#{Sh.rbenv_ruby} #{path} #{flock} #{rake_task} --silent :output"
job_type :bash,  %{#{Sh.rbenv_ruby} #{context} #{path} #{mutex} "#{helper} #{flock} nice -n 19 #{bash_task} :output #{no_helper}"}
job_type :bash!, %{#{Sh.rbenv_ruby} #{context} #{path} #{mutex} "#{helper} #{flock} #{bash_task} :output #{no_helper}"}
