#include "some_code.hpp"
#include "all.hpp"
#include "some_other_code.hpp"

extern "C"
void Init_ext() {
  init_some_code();
  Rice::Module rb_mRoot = Rice::define_module("Root");
  rb_mRoot.const_set("CONSTANT", 2);
  rb_mRoot.define_singleton_function("root", &Root::root);
  Rice::Data_Type<Root::Simple> rb_cRoot_dc_Simple = Rice::define_class_under<Root::Simple>(rb_mRoot, "Simple");
  rb_cRoot_dc_Simple.define_method("simple", &Root::Simple::simple);
  Rice::Module rb_mRoot_dc_Name = Rice::define_module_under(rb_mRoot, "Name");
  rb_mRoot_dc_Name.define_method("name", &Root::Name::name);
  Rice::Data_Type<Root::Name::BaseAlias> rb_cRoot_dc_Name_dc_BaseAlias = Rice::define_class_under<Root::Name::BaseAlias>(rb_mRoot_dc_Name, "Base");
  rb_cRoot_dc_Name_dc_BaseAlias.include_module(rb_mRoot_dc_Name);
  rb_cRoot_dc_Name_dc_BaseAlias.define_attr("both", &Root::Name::BaseAlias::readWrite);
  rb_cRoot_dc_Name_dc_BaseAlias.define_attr("mode", &Root::Name::BaseAlias::mode);
  rb_cRoot_dc_Name_dc_BaseAlias.define_attr("read_only", &Root::Name::BaseAlias::readOnly, Rice::AttrAccess::Read);
  rb_cRoot_dc_Name_dc_BaseAlias.define_singleton_attr("static_write_only", &Root::Name::BaseAlias::writeOnly, Rice::AttrAccess::Write);
  rb_cRoot_dc_Name_dc_BaseAlias.define_singleton_function("base", &Root::Name::BaseAlias::base_alias, Rice::Arg("arg_1"), Rice::Arg("arg_2") = (std::string)"value");
  rb_cRoot_dc_Name_dc_BaseAlias.define_method("initialize", &Root::Name::BaseAlias::initialize, Rice::Arg("int"), Rice::Arg("float"));
  Rice::Data_Type<Root::TestAlias> rb_cRoot_dc_TestAlias = Rice::define_class_under<Root::TestAlias, Root::Name::BaseAlias>(rb_mRoot, "Test");
  rb_cRoot_dc_TestAlias.include_module(rb_mRoot_dc_Name);
  rb_cRoot_dc_TestAlias.define_constructor(Rice::Constructor<Root::TestAlias, int, float>(Rice::Arg("arg1"), Rice::Arg("arg_2") = 1.2));
  rb_cRoot_dc_TestAlias.define_function("test", &Root::TestAlias::test, Rice::Arg("arg"));
  rb_cRoot_dc_TestAlias.define_function("outside", &::outside);
  typedef size_t (Root::TestAlias::*rb_root_test_alias_value__1__)();
  rb_cRoot_dc_TestAlias.define_method("value", rb_root_test_alias_value__1__(&Root::TestAlias::value));
  typedef void (Root::TestAlias::*rb_root_test_alias_value__2__)(size_t);
  rb_cRoot_dc_TestAlias.define_method("value=", rb_root_test_alias_value__2__(&Root::TestAlias::value));
  rb_cRoot_dc_TestAlias.define_method("lambda", [](Object& self) {
    return test_hello();
  });
  define_global_function("global", &global);
  Rice::Class rb_cGlobal = Rice::define_class("Global");
  rb_cGlobal.define_method("global", &::global);
  Rice::Module rb_mEmpty = Rice::define_module("Empty");
  init_some_other_code();
}
