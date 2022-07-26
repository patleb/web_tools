export deploy_path="$HOME/${stage}"
export current_path="${deploy_path}/current"
export releases_path="${deploy_path}/releases"
export release_path="${releases_path}/${revision}"
export repo_path=${repo_path:-"${deploy_path}/repo"}
export shared_path="${deploy_path}/shared"
export revision_log="${deploy_path}/revisions.log"
export git_shallow_clone=${git_shallow_clone:-false}
export git_verify_commit=${git_verify_commit:-false}
export keep_releases=${keep_releases:-5}
