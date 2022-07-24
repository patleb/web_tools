export deploy_dir="${role}-${env}-${app}"
export deploy_path="$HOME/${deploy_dir}"
export current_path="${deploy_path}/current"
export releases_path="${deploy_path}/releases"
export release_path="${releases_path}/${revision}"
export repo_path=${repo_path:-"${deploy_path}/repo"}
export shared_path="${deploy_path}/shared"
export revision_log="${deploy_path}/revisions.log"
export git_shallow_clone=${git_shallow_clone:-false}
export git_verify_commit=${git_verify_commit:-false}
export keep_releases=${keep_releases:-5}

git_ssh_src="$(sun.template_path /tmp/git_ssh.sh)"
git_ssh_dst=/tmp/git_ssh-$(openssl rand -hex 10).sh
cp $git_ssh_src $git_ssh_dst
chmod 700 $git_ssh_dst
export GIT_SSH=$git_ssh_dst
export GIT_ASKPASS=/bin/echo

desc() {
  echo.lightgray "$@"
}
