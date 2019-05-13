module Sh::Rbenv
  def rbenv_export(deployer_name)
    %{export PATH="/home/#{deployer_name}/.rbenv/bin:/home/#{deployer_name}/.rbenv/plugins/ruby-build/bin:$PATH"}
  end

  def rbenv_init
    'eval "$(rbenv init -)"'
  end
end
