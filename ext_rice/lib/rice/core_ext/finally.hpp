// References
// https://www.codeproject.com/Tips/476970/finally-clause-in-Cplusplus
// finally ensure([&]{
//   ...
// });
class finally {
  std::function< void(void) > functor;

  public:

  finally(const std::function< void(void) > & functor):
    functor(functor) {
  }
  <%= no_copy :finally %>

  ~finally() {
    functor();
  }
};
