module Sh::Rbenv
  def rbenv_ruby
    'eval "$(/home/deployer/.rbenv/bin/rbenv init - --no-rehash bash)";'
  end
end
