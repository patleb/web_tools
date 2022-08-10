module Sh::Rbenv
  def rbenv_ruby
    "#{rbenv_export}; #{rbenv_init};"
  end

  def rbenv_export
    %{export PATH="/home/deployer/.rbenv/bin:/home/deployer/.rbenv/plugins/ruby-build/bin:$PATH"}
  end

  def rbenv_init
    'eval "$(rbenv init -)"'
  end
end
