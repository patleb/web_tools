cd ${release_path}

desc "Compile Rice C++ extension for ${stage}"
cp "${current_path}/app/rice/${rice_target}.sha256" "app/rice/${rice_target}.sha256" 2> /dev/null || :
cp "${current_path}/app/rice/${rice_target}.so"     "app/rice/${rice_target}.so"     2> /dev/null || :
CCACHE=false rake rice:compile

cd.back
