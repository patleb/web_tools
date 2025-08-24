assets_keep=${assets_keep:-10}
assets_age=${assets_age:-0}

cd ${release_path}

desc 'Install all JavaScript dependencies as specified via Yarn'
rake yarn:install

desc "Compile JavaScript packs using webpack for ${stage} with digests"
rake shakapacker:compile

desc 'Remove old compiled webpacks'
rake shakapacker:clean[${assets_keep},${assets_keep}]

cd.back
