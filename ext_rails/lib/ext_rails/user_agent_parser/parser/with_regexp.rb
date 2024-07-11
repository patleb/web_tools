MonkeyPatch.add{['user_agent_parser', 'lib/user_agent_parser/parser.rb', '0de199e60559cc5fc3670bf7a336763bd57d5971f78102cdc0659d5a4727cf70']}

module UserAgentParser::Parser::WithRegexp
  private

  def parse_pattern(patterns)
    patterns.map do |pattern|
      pattern = pattern.dup
      pattern[:regex] = Regexp.new(pattern.delete('regex'), pattern.delete('regex_flag'))
      pattern
    end
  end
end
UserAgentParser::Parser.prepend UserAgentParser::Parser::WithRegexp
