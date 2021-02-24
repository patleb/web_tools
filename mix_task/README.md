# MixTask

## Notes

```sh
bundle exec cap production rake TASK='mix_task:pg_dump -- --includes=table_name_1,table_name_2'
bundle exec cap production files:download[~/app_admin_production/current/db/dump.pg,db/dump.pg]
bundle exec rake mix_task:pg_truncate -- --includes=table_name_1,table_name_2
bundle exec rake mix_task:pg_restore PG_OPTIONS=--data-only -- --includes=table_name_1,table_name_2

bundle exec cap staging rake TASK=mix_task:pg_dump
bundle exec cap staging files:download[~/app_admin_staging/current/db/dump.pg,db/dump.pg]
bin/rails db:environment:set RAILS_ENV=development && bundle exec rake db:drop db:create
bundle exec rake mix_task:pg_restore
```

