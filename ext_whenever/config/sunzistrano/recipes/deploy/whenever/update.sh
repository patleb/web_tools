cd ${release_path}

desc "Update application's crontab entries using Whenever"
bin/whenever --update-crontab ${stage} --set "environment=${env}&application=${app}"

cd - > /dev/null
