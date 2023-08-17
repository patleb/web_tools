#include "some_code.hpp"
#include "all.hpp"
#include "some_other_code.hpp"
using namespace Rice;

extern "C"
void Init_ext() {
  init_some_code();
  Module rb_mRoot = define_module("Root");
  rb_mRoot.const_set("CONSTANT", 2);
  rb_mRoot.define_singleton_function("root", &Root::root);
  Data_Type<Root::Simple> rb_cRoot_dc_Simple = define_class_under<Root::Simple>(rb_mRoot, "Simple");
  rb_cRoot_dc_Simple.define_method("simple", &Root::Simple::simple);
  Module rb_mRoot_dc_Name = define_module_under(rb_mRoot, "Name");
  rb_mRoot_dc_Name.define_method("name", &Root::Name::name);
  Data_Type<Root::Name::BaseAlias> rb_cRoot_dc_Name_dc_BaseAlias = define_class_under<Root::Name::BaseAlias>(rb_mRoot_dc_Name, "Base");
  rb_cRoot_dc_Name_dc_BaseAlias.include_module(rb_mRoot_dc_Name);
  rb_cRoot_dc_Name_dc_BaseAlias.define_attr("both", &Root::Name::BaseAlias::readWrite);
  rb_cRoot_dc_Name_dc_BaseAlias.define_attr("mode", &Root::Name::BaseAlias::mode);
  rb_cRoot_dc_Name_dc_BaseAlias.define_attr("read_only", &Root::Name::BaseAlias::readOnly, AttrAccess::Read);
  rb_cRoot_dc_Name_dc_BaseAlias.define_singleton_attr("static_write_only", &Root::Name::BaseAlias::writeOnly, AttrAccess::Write);
  rb_cRoot_dc_Name_dc_BaseAlias.define_singleton_function("base", &Root::Name::BaseAlias::base_alias, Arg("arg_1"), Arg("arg_2") = (std::string)"value");
  rb_cRoot_dc_Name_dc_BaseAlias.define_method("initialize", &Root::Name::BaseAlias::initialize, Arg("int"), Arg("float"));
  Data_Type<Root::TestAlias> rb_cRoot_dc_TestAlias = define_class_under<Root::TestAlias, Root::Name::BaseAlias>(rb_mRoot, "Test");
  rb_cRoot_dc_TestAlias.include_module(rb_mRoot_dc_Name);
  rb_cRoot_dc_TestAlias.define_constructor(Constructor<Root::TestAlias, int, float>(), Arg("arg1"), Arg("arg_2") = 1.2);
  rb_cRoot_dc_TestAlias.define_function("test", &Root::TestAlias::test, Arg("arg"));
  rb_cRoot_dc_TestAlias.define_function("outside", &::outside);
  typedef size_t (Root::TestAlias::*rb_root_test_alias_value__1__)();
  rb_cRoot_dc_TestAlias.define_method("value", rb_root_test_alias_value__1__(&Root::TestAlias::value));
  typedef void (Root::TestAlias::*rb_root_test_alias_value__2__)(size_t);
  rb_cRoot_dc_TestAlias.define_method("value=", rb_root_test_alias_value__2__(&Root::TestAlias::value));
  rb_cRoot_dc_TestAlias.define_method("arg_alive", &Root::TestAlias::arg_alive, Arg("arg_name").keepAlive());
  rb_cRoot_dc_TestAlias.define_method("arg_value", &Root::TestAlias::arg_value, Arg("arg_name").setValue());
  rb_cRoot_dc_TestAlias.define_method("return_alive", &Root::TestAlias::return_alive, Return.keepAlive());
  rb_cRoot_dc_TestAlias.define_method("return_value", &Root::TestAlias::return_value, Return.setValue());
  rb_cRoot_dc_TestAlias.define_method("return_owner", &Root::TestAlias::return_owner, Return.takeOwnership());
  rb_cRoot_dc_TestAlias.define_method("lambda", [](Object& self) -> std::vector<int32_t>& {
    return test_hello();
  });
  define_global_function("global", &global);
  Class rb_cGlobal = define_class("Global");
  rb_cGlobal.define_method("global", &::global);
  Module rb_mEmpty = define_module("Empty");
  init_some_other_code();
}
