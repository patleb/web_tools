class ERB
  def self.template(src, binding = nil, lean: false, **)
    path = Pathname.new(src)
    if lean
      variables = []
      content = path.each_line.with_object(+'') do |line, content|
        case line
        when / do \|([^|]+)\|/
          if $1.match? /^[\WA-Z_0-9]+$/
            tokens = $1.split(',').map{ |token| token.gsub(/\W/, '') }
            tokens.each do |token|
              line.gsub! /(\W)#{token}(\W)/, "\\1#{token.downcase}\\2"
            end
            variables.push tokens
          else
            variables.push []
          end
        when / end /
          variables.pop
        else
          variables.each do |tokens|
            tokens.each do |token|
              line.gsub! /(\W)#{token}(\W)/, "\\1<%= #{token.downcase} %>\\2"
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
