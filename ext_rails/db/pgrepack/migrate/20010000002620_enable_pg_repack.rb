class EnablePgRepack < ActiveRecord::Migration[6.1]
  def change
    # TODO https://gitlab.com/gitlab-com/gl-infra/gitlab-pgrepack
    enable_extension 'pg_repack'
  end
end
