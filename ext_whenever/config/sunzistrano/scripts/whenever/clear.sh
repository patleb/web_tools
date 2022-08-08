desc "Clear application's crontab entries using Whenever"
cd ${release_path}
bin/whenever --clear-crontab ${stage}
cd.back
