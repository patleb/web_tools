require './test/spec_helper'

class ShTest < Minitest::TestCase
  let(:file){ Pathname.new('ext_ruby/test/fixtures/files/sub.txt') }
  let(:lines){ [
    "line 0",
    "line 1 'end'",
    "line 0 'end'",
    "line 1 'end'",
    "line $"
  ] }

  context '.sub' do
    test 'replace the first line' do
      expected = lines.join("\n").sub('line 0', 'replaced')
      ["line 0", /line 0/].each do |matcher|
        assert_equal expected, output(Sh.sub file, matcher, 'replaced')
      end
    end

    test 'exit with error if the line is missing' do
      assert_equal false, status(Sh.sub file, 'line unknown', 'nothing').success?
    end

    test 'not escape variables' do
      expected = lines.join("\n").sub('line 0', 'replaced')
      assert_equal expected, output(Sh.sub(file, '$LINE', 'replaced', escape: false), before: 'LINE="line 0";')
    end
  end

  context '.gsub' do
    test 'replace all lines' do
      expected = lines.join("\n").gsub('line 0', 'replaced')
      assert_equal expected, output(Sh.gsub file, 'line 0', 'replaced')
    end
  end

  context '.delete_line' do
    test 'delete the first line' do
      expected = lines.drop(1).join("\n")
      assert_equal expected, output(Sh.delete_line file, 'line 0')
    end

    test 'delete the last line' do
      expected = lines.reverse.drop(1).reverse.join("\n")
      assert_equal expected, output(Sh.delete_line file, 'line $')
    end

    test 'ignore missing line' do
      assert_equal true, status(Sh.delete_line file, 'line unknown').success?
    end
  end

  context '.delete_lines' do
    test 'delete all lines' do
      expected = lines.reject{ |line| line.include? 'line 0' }.join("\n")
      assert_equal expected, output(Sh.delete_lines file, 'line 0')
    end
  end

  context '.escape_newlines' do
    test 'double escape newlines' do
      expected = lines.join("\n").gsub(/\r?\n/, "\\\\\\\\n")
      assert_equal expected, output(Sh.escape_newlines file)
    end
  end

  def output(cmd, **_)
    sh(cmd, **_)[0]
  end

  def status(cmd, **_)
    sh(cmd, **_)[2]
  end

  def sh(cmd, before: nil)
    Open3.capture3("#{before}#{cmd}")
  end
end
