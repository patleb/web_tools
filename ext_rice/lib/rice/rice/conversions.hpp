namespace Rice::detail {
  template<>
  class From_Ruby<signed char &> {
    public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg):
      arg_(arg) {
    }

    Convertible is_convertible(VALUE value) {
      return FromRubyFundamental<signed char>::is_convertible(value);
    }

    signed char& convert(VALUE value) {
      if (value == Qnil && this->arg_ && this->arg_->hasDefaultValue()) {
        return this->arg_->defaultValue<signed char>();
      } else {
        this->converted_ = FromRubyFundamental<signed char>::convert(value);
        return this->converted_;
      }
    }

    private:

    Arg* arg_ = nullptr;
    signed char converted_ = 0;
  };
}
