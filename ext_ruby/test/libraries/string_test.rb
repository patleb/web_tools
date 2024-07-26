require './test/spec_helper'

class StringTest < Minitest::TestCase
  test '#to_bytes' do
    assert_equal 1024000, '1,0 Mo'.to_bytes(:db)
    assert_equal 1024000, '1.0 mb'.to_bytes(:db)
    assert_equal 1048576, '1.0 MB'.to_bytes
  end

  test '#to_args' do
    assert_equal 1, '1'.to_args
    assert_equal [1, 2], '[1, 2]'.to_args
    assert_equal [1, 'a' => 'b'], '[1, a: "b"]'.to_args
    assert_equal(
      { 'a' => 'b', 'c' => [1, 'd', nil, 2.0, '3e1000']},
      '{ a: "b", "c": [1, "d", nil, 2.0, 3e1000] }'.to_args
    )
    assert_equal(
      [nil, {"a"=>{"b"=>{"c"=>nil, "d"=>[nil, nil]}, "e"=>nil} }, nil],
      '[nil, { a: { b: {c: nil, d: [nil, nil] }, e: nil } }, nil]'.to_args
    )
  end

  test '#match_glob?' do
    assert 'test_records'.match_glob? 'test_*'
    assert 'test_records'.match_glob? 't*t_*c*'
  end

  test '#html_blank?' do
    assert '< p >< /p> <p />&nbsp;< br >&nbsp;< br /> &nbsp;'.html_blank?
  end

  test '#simplify' do
    assert_equal 'e a 3 2 5 a b 1 true', 'é-à{3,2,5}_[ä/b]  ~+-1 && true'.simplify
  end

  test '#trigrams, #similarity' do
    token = 'éléphants et lions'
    assert_equal(
      ['  e','  l',' el',' et',' li','ant','ele','eph','et ','han','ion','lep','lio','ns ','nts','ons','pha','ts '],
      token.trigrams.to_a
    )
    assert_equal ['  a',' ab','abc','bc '], 'abc'.trigrams.to_a
    assert_equal ['  a',' ab','ab '], 'ab'.trigrams.to_a
    assert_equal ['  a',' a '], 'a'.trigrams.to_a
    assert_equal 1.0, token.similarity(token)
    assert_equal 0.0, token.similarity('')
    assert_equal 0.55556, token.similarity('éléphants').round(5)
    assert_equal 0.33333, token.similarity('lions').round(5)
    assert_equal 0.09677, token.similarity('alafant and liar').round(5)
    assert_equal 0.0, token.similarity('completely different').round(5)
  end

  test '#squish_numbers' do
    string = "UUID:#{SecureRandom.uuid}, HEX:0x#{12_345.to_s(16)}, MD5:#{SecureRandom.hex(16)}, FLOAT:9e-5, DEC:-1234.5, INT:+67, INF:-infinity"
    assert_equal 'UUID:*, HEX:*, MD*:*, FLOAT:*, DEC:*, INT:*, INF:*', string.squish_numbers
  end

  test '#squish_char' do
    assert_equal '/ab/c/d/::/', '//ab/c///d/:://'.squish_char('/')
  end

  test '#escape_single_quotes, #unescape_single_quotes' do
    string = "'quoted' and 'this' as 'well'"
    assert_equal "\\x27quoted\\x27 and \\x27this\\x27 as \\x27well\\x27", string.escape_single_quotes(:ascii)
    assert_equal string, string.escape_single_quotes.unescape_single_quotes
    assert_equal "'\\''quoted'\\'' and '\\''this'\\'' as '\\''well'\\''", string.escape_single_quotes(:shell)
    assert_equal string, string.escape_single_quotes(:shell).unescape_single_quotes(:shell)
    assert_equal "\\'quoted\\' and \\'this\\' as \\'well\\'", string.escape_single_quotes(:char)
    assert_equal string, string.escape_single_quotes(:char).unescape_single_quotes(:char)
  end

  test '#escape_newlines, #unescape_newlines' do
    string = "\r\n some words \nmore words\nafter\r\nthis ending\n"
    assert_equal "\\n some words \\nmore words\\nafter\\nthis ending\\n", string.escape_newlines
    assert_equal string.gsub(/\r/, ''), string.escape_newlines.unescape_newlines
  end

  test '#partition_at' do
    string = 'some string at'
    assert_equal ['some string at', ''], string.partition_at(string.size + 1)
    assert_equal ['some ', 'string at'], string.partition_at(5)
    assert_equal ['so', 'me string at'], string.partition_at(5, separator: 'me')
    assert_equal ['so', 'me string at'], string.partition_at(5, separator: 'xo', fallback: 'me')
  end

  test '#index_n, #index_all' do
    string = 'some array, with values, and such'
    assert_equal 10, string.index_n(',')
    assert_equal 23, string.index_n(/, *\w+/, 2)
    assert_equal nil, string.index_n(',', 3)
    assert_equal [10, 23], string.index_all(',')
    assert_equal [23], string.index_all(/, *\w+/, 2)
    assert_equal [], string.index_all(',', 3)
  end
end
