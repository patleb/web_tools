#include "unittest.hpp"
#include "embed_ruby.hpp"
#include <rice/rice.hpp>

#include "ext_rice/core_ext/c.hpp"
#include <regex>

using namespace Rice;

TESTSUITE(c);

SETUP(c)
{
  embed_ruby();
}

TESTCASE(timestamp)
{
  std::string timestamp = C::timestamp();
  std::regex check ("\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}.\\d{6} UTC");
  ASSERT(std::regex_match(timestamp, check));
}
