keep_assets=${keep_assets:-10}

cd ${release_path}

desc 'Install all JavaScript dependencies as specified via Yarn'
bin/rake webpacker:yarn_install

desc "Compile JavaScript packs using webpack for ${stage} with digests"
bin/rake webpacker:compile

desc 'Remove old compiled webpacks'
bin/rake webpacker:clean[${keep_assets}]

cd.back
