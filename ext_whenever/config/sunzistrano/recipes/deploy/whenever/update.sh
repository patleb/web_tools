cd ${release_path}

desc "Update application's crontab entries using Whenever"
sun.whenever_update

cd - > /dev/null
