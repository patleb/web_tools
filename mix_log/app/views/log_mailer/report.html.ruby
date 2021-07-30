code_ style: 'white-space: pre;' do
  sanitize(@report.pretty_json).gsub(/\r?\n/, '<br>').gsub(' ', '&nbsp;').html_safe
end
