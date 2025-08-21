// before_include
#include "some_code.hpp"
//include
#include "all.hpp"
#include "ext_rice/rice.hpp"
// after_include
#include "some_other_code.hpp"
using namespace Rice;

extern "C" void Init_ext() {
  // before_initialize
  init_some_code();
  // initialize
  detail::Registries::instance.handlers.set(ExceptionHandler());
  Module rb_mRoot = define_module("Root");
  rb_mRoot.define_constant("CONSTANT", (int)Root::MODULE_CONSTANT);
  Enum<Root::COLOR> rb_eRoot_dc_COLOR = define_enum_under<Root::COLOR>("COLOR", rb_mRoot);
  rb_eRoot_dc_COLOR.define_value("RED", Root::COLOR::RED);
  rb_eRoot_dc_COLOR.define_value("BLUE", Root::COLOR::BLUE);
  rb_eRoot_dc_COLOR.define_value("GREEN", Root::COLOR::GREEN);
  rb_mRoot.define_singleton_function("root", &Root::root);
  Data_Type<Root::Simple> rb_cRoot_dc_Simple = define_class_under<Root::Simple, Another>(rb_mRoot, "Simple");
  Enum<Root::Simple::PROPS> rb_eRoot_dc_Simple_dc_PROPS = define_enum_under<Root::Simple::PROPS>("Props", rb_cRoot_dc_Simple);
  rb_eRoot_dc_Simple_dc_PROPS.define_value("VALUE_A1", Root::Simple::PROPS::ValueA1);
  rb_eRoot_dc_Simple_dc_PROPS.define_value("VALUE_B2", Root::Simple::PROPS::ValueB2);
  rb_eRoot_dc_Simple_dc_PROPS.define_value("VALUE_C3", Root::Simple::PROPS::ValueC3);
  rb_cRoot_dc_Simple.define_method("simple", &Root::Simple::simple);
  Module rb_mRoot_dc_Name = define_module_under(rb_mRoot, "Name");
  rb_mRoot_dc_Name.define_method("name", &Root::Name::name);
  Data_Type<Root::Name::BaseAlias> rb_cRoot_dc_Name_dc_BaseAlias = define_class_under<Root::Name::BaseAlias>(rb_mRoot_dc_Name, "Base");
  rb_cRoot_dc_Name_dc_BaseAlias.define_attr("both", &Root::Name::BaseAlias::readWrite);
  rb_cRoot_dc_Name_dc_BaseAlias.define_attr("mode", &Root::Name::BaseAlias::mode);
  rb_cRoot_dc_Name_dc_BaseAlias.define_attr("read_only", &Root::Name::BaseAlias::readOnly, AttrAccess::Read);
  rb_cRoot_dc_Name_dc_BaseAlias.define_attr("write_only", &Root::Name::BaseAlias::writeOnly, AttrAccess::Write);
  rb_cRoot_dc_Name_dc_BaseAlias.define_singleton_attr("static_write_only", &Root::Name::BaseAlias::writeOnly, AttrAccess::Write);
  rb_cRoot_dc_Name_dc_BaseAlias.define_singleton_function("base", &Root::Name::BaseAlias::base_alias, Arg("arg_1"), Arg("arg_2") = (std::string)"value");
  rb_cRoot_dc_Name_dc_BaseAlias.define_singleton_function("camel_case", &Root::Name::BaseAlias::CamelCase);
  rb_cRoot_dc_Name_dc_BaseAlias.define_method("initialize", &Root::Name::BaseAlias::initialize, Arg("int"), Arg("float"));
  rb_cRoot_dc_Name_dc_BaseAlias.define_method("camel_case", &Root::Name::BaseAlias::CamelCase);
  Data_Type<Root::TestAlias> rb_cRoot_dc_TestAlias = define_class_under<Root::TestAlias, Root::Name::BaseAlias>(rb_mRoot, "Test");
  rb_cRoot_dc_TestAlias.define_constructor(Constructor<Root::TestAlias, int, float>(), Arg("arg1"), Arg("arg_2") = 1.2);
  rb_cRoot_dc_TestAlias.define_function("test", &Root::TestAlias::test, Arg("arg"));
  rb_cRoot_dc_TestAlias.define_function("outside", &::outside<int>);
  using rb_root_test_alias_value_1 = size_t (Root::TestAlias::*)();
  rb_cRoot_dc_TestAlias.define_method<rb_root_test_alias_value_1>("value", &Root::TestAlias::value);
  using rb_root_test_alias_value_2 = void (Root::TestAlias::*)(size_t);
  rb_cRoot_dc_TestAlias.define_method<rb_root_test_alias_value_2>("value=", &Root::TestAlias::value);
  rb_cRoot_dc_TestAlias.define_method("arg_alive", &Root::TestAlias::arg_alive, Arg("arg_name").keepAlive());
  rb_cRoot_dc_TestAlias.define_method("arg_value", &Root::TestAlias::arg_value, Arg("arg_name").setValue());
  rb_cRoot_dc_TestAlias.define_method("return_alive", &Root::TestAlias::return_alive, Return().keepAlive());
  rb_cRoot_dc_TestAlias.define_method("return_value", &Root::TestAlias::return_value, Return().setValue());
  rb_cRoot_dc_TestAlias.define_method("return_owner", &Root::TestAlias::return_owner, Return().takeOwnership());
  rb_cRoot_dc_TestAlias.define_method("lambda", [](Object& self) -> std::vector<int32_t>& {
    return test_hello();
  });
  Data_Type<Overload> rb_cOverload = define_class<Overload>("Overload");
  rb_cOverload.define_constructor(Constructor<Overload>());
  rb_cOverload.define_constructor(Constructor<Overload, const Overload&>());
  rb_cOverload.define_constructor(Constructor<Overload, Overload&&>());
  rb_cOverload.define_constructor(Constructor<Overload, int, float>());
  rb_cOverload.define_constructor(Constructor<Overload, int, float>(), Arg("arg1"), Arg("arg_2") = 1.2);
  using rb_overload_name_1 = vectot<int>& (Overload::*)() const;
  rb_cOverload.define_method<rb_overload_name_1>("name", &Overload::name);
  using rb_overload_name_2 = size_t (Overload::*)();
  rb_cOverload.define_method<rb_overload_name_2>("name", &Overload::name< int, bool >);
  using rb_overload_name_3 = void (Overload::*)(size_t);
  rb_cOverload.define_method<rb_overload_name_3>("name", &Overload::name);
  using rb_overload_name_4 = bool (Overload::*)(int, std::string);
  rb_cOverload.define_method<rb_overload_name_4>("name", &Overload::name, Arg("arg_1"), Arg("arg_2") = (std::string)"value");
  define_global_function("global", &global);
  Data_Type<Global> rb_cGlobal = define_class<Global>("Global");
  rb_cGlobal.define_method("global", &::global);
  Module rb_mEmpty = define_module("Empty");
  Enum<SEASON> rb_eSEASON = define_enum<SEASON>("SEASON");
  rb_eSEASON.define_value("SPRING", SEASON::SPRING);
  rb_eSEASON.define_value("SUMMER", SEASON::SUMMER);
  rb_eSEASON.define_value("FALL", SEASON::FALL);
  rb_eSEASON.define_value("WINTER", SEASON::WINTER);
  // after_initialize
  init_some_other_code();
}
