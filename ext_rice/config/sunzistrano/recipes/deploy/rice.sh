TARGET=<%= Rice.target %>

cd ${release_path}

desc "Compile Rice C++ extension for ${stage}"
cp "${current_path}/app/rice/${TARGET}.sha256" "app/rice/${TARGET}.sha256" 2> /dev/null || :
cp "${current_path}/app/rice/${TARGET}.so"     "app/rice/${TARGET}.so"     2> /dev/null || :
CCACHE=false bin/rake rice:compile

cd.back
