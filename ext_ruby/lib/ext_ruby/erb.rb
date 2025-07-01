class ERB
  def self.template(src, binding = nil, lean: false, **)
    path = Pathname.new(src)
    if lean
      vars, block_vars = [], []
      content = path.each_line.with_object(+'') do |line, content|
        case line
        when /<%-? +([A-Z_0-9, ]+) *= *[^%]+%>/
          tokens = $1.split(',').map(&:strip)
          tokens.each do |token|
            line.gsub! /(\W)#{token}(\W)/, "\\1#{token.downcase}_\\2"
          end
          vars.push tokens
          block_vars.each do |tokens|
            tokens.each do |token|
              line.gsub! /([^@])@#{token}(\W)/, "\\1#{token.downcase}_\\2"
            end
          end
        when /<%-? +.+ do \|([^|]+)\|/
          if $1.match? /^[\WA-Z_0-9]+$/
            tokens = $1.split(',').map{ |token| token.gsub(/\W/, '') }
            tokens.each do |token|
              line.gsub! /(\W)#{token}(\W)/, "\\1#{token.downcase}_\\2"
            end
            (vars + block_vars).each do |tokens|
              tokens.each do |token|
                line.gsub! /([^@])@#{token}(\W)/, "\\1#{token.downcase}_\\2"
              end
            end
            block_vars.push tokens
          else
            block_vars.push []
          end
        when /<%-? +(if|unless|case)/
          (vars + block_vars).each do |tokens|
            tokens.each do |token|
              line.gsub! /([^@])@#{token}(\W)/, "\\1#{token.downcase}_\\2"
            end
          end
          block_vars.push []
        when /<%-? +end /
          block_vars.pop
        else
          (vars + block_vars).each do |tokens|
            tokens.each do |token|
              line.gsub! /([^-]-?)-#{token}-(-?[^-])/, "\\1<%= #{token.downcase}_ %>\\2"
              line.gsub! /([^@])@#{token}(\W)/, "\\1#{token.downcase}_\\2"
              line.gsub! /(\W)#{token}(\W)/, "\\1<%= #{token.downcase}_ %>\\2"
            end
          end
        end
        content << line
      end
    else
      content = path.read
    end
    erb = ERB.new(content, **)
    binding ? erb.result(binding) : erb.result
  end
end
