Sunzistrano
===========

```
"The supreme art of war is to subdue the enemy without fighting." - Sunzi
```

Sunzistrano is the easiest [server provisioning](http://en.wikipedia.org/wiki/Provisioning#Server_provisioning) utility designed for mere mortals. If Chef or Puppet is driving you nuts, try Sunzistrano!

Sunzistrano assumes that modern Linux distributions have (mostly) sane defaults and great package managers.

Its design goals are:

* **It's just shell script.** No clunky Ruby DSL involved. Most of the information about server configuration on the web is written in shell commands. Just copy-paste them, rather than translate it into an arbitrary DSL. Also, Bash is the greatest common denominator on minimum Linux installs.
* **Focus on diff from default.** No big-bang overwriting. Append or replace the smallest possible piece of data in a config file. Loads of custom configurations make it difficult to understand what you are really doing.
* **Always use the root user.** Think twice before blindly assuming you need a regular user - it doesn't add any security benefit for server provisioning, it just adds extra verbosity for nothing. However, it doesn't mean that you shouldn't create regular users with Sunzistrano - feel free to write your own recipes.
* **Minimum dependencies.** No configuration server required. You don't even need a Ruby runtime on the remote server.

Provisioning
------------

* start new instances with same region as the database (t2.micro/24GB admin, t2.small/16GB api)

* point local machine to new instances ip

    $ ssh-keygen -f "$HOME/.ssh/known_hosts" -R admin.domain.com
    $ ssh-keygen -f "$HOME/.ssh/known_hosts" -R api.domain.com
    $ sudo vi /etc/hosts

xxx.xxx.xxx.xxx admin.domain.com
xxx.xxx.xxx.xxx api.domain.com

* provision new instances

    $ bundle exec sun provision production system
    $ bundle exec sun provision production:app_api system

* point local machine to old instances ip

    $ ssh-keygen -f "$HOME/.ssh/known_hosts" -R admin.domain.com
    $ ssh-keygen -f "$HOME/.ssh/known_hosts" -R api.domain.com
    $ sudo vi /etc/hosts

* disable applications

    $ bundle exec cap production whenever:clear_crontab
    $ bundle exec cap production nginx:app:maintenance:enable
    $ bundle exec cap production:app_api nginx:app:maintenance:enable # or nginx:app:disable if database connections must be closed

or

    $ RAILS_ENV=production bundle exec whenever -c app_admin_production
    $ sudo rm -f /etc/nginx/sites-enabled/app_admin_production && sudo systemctl reload nginx
    $ sudo rm -f /etc/nginx/sites-enabled/app_api_production && sudo systemctl reload nginx

* backup important files

    $ bundle exec cap production rake TASK='ext_rake:backup -- --model=app_logs'
    $ bundle exec cap production rake TASK='ext_rake:backup -- --model=sys_logs'
    $ bundle exec cap production files:download[~/app_admin_production/shared/tmp/backups/.data/model_name/S3.yml,tmp/S3.yml]

or

    $ RAILS_ENV=production bundle exec rake ext_rake:backup -- --model=app_logs
    $ RAILS_ENV=production bundle exec rake ext_rake:backup -- --model=sys_logs
    $ download shared/log and shared/tmp/backups/.data/model_name/S3.yml

TODO: app_logs/sys_logs backup for sub application (ex.: production:app_api)
* make a manual backup of postgres if necessary
* upgrade postgres if necessary

* point local machine to new instances ip

    $ ssh-keygen -f "$HOME/.ssh/known_hosts" -R admin.domain.com
    $ ssh-keygen -f "$HOME/.ssh/known_hosts" -R api.domain.com
    $ sudo vi /etc/hosts

* deploy applications

    $ bundle exec cap production deploy:push
    $ bundle exec cap production:app_api deploy:push
    $ bundle exec cap production files:mkdir[~/app_admin_production/shared/tmp/backups/.data/model_name]
    $ bundle exec cap production files:upload[tmp/S3.yml,~/app_admin_production/shared/tmp/backups/.data/model_name/S3.yml,user]

* point local machine to old instances ip

    $ ssh-keygen -f "$HOME/.ssh/known_hosts" -R admin.domain.com
    $ ssh-keygen -f "$HOME/.ssh/known_hosts" -R api.domain.com
    $ ssh-keygen -f "$HOME/.ssh/known_hosts" -R xxx.xxx.xxx.xxx
    $ ssh-keygen -f "$HOME/.ssh/known_hosts" -R xxx.xxx.xxx.xxx
    $ sudo vi /etc/hosts

* point elastic ips to new instances
* terminate old instances
* reassign alarms

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/recognize-expanded-volume-linux.html

Notes
-----
sudo cat sun_provision.log | grep -A 1 -B 1 -e '\(Recipe\|Done\) \['

Credits
-------

Special thanks to the owner of [sunzi](https://github.com/kenn/sunzi), the present gem is pretty much a rewritten copy suited to work with Rails and Capistrano.
