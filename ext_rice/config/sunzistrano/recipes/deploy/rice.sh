cd ${release_path}

desc "Compile Rice C++ extension for ${stage}"
bin/rake rice:compile

cd.back
