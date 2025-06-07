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

struct nullstate {};

namespace Rice::detail {
  template<>
  struct Type<nullstate> {
    constexpr static bool verify()
    {
      return true;
    }
  };

  template<>
  class To_Ruby<nullstate>
  {
  public:
    VALUE convert(const nullstate& _)
    {
      return Qnil;
    }
  };

  template<>
  class To_Ruby<nullstate&>
  {
  public:
    static VALUE convert(const nullstate& data, bool takeOwnership = false)
    {
      return Qnil;
    }
  };

  template<>
  class From_Ruby<nullstate>
  {
  public:
    Convertible is_convertible(VALUE value)
    {
      switch (rb_type(value))
      {
        case RUBY_T_NIL:
          return Convertible::Exact;
        default:
          return Convertible::None;
      }
    }

    nullstate convert(VALUE value)
    {
      return nullstate();
    }
  };

  template<>
  class From_Ruby<nullstate&>
  {
  public:
    Convertible is_convertible(VALUE value)
    {
      switch (rb_type(value))
      {
        case RUBY_T_NIL:
          return Convertible::Exact;
        default:
          return Convertible::None;
      }
    }

    nullstate& convert(VALUE value)
    {
      this->converted_ = nullstate();
      return this->converted_;
    }
    
  private:
    nullstate converted_ = nullstate();
  };
}
