desc "Update application's crontab entries using Whenever"
cd ${release_path}
bin/whenever --update-crontab ${stage} --set "environment=${env}&application=${app}"
cd.back
