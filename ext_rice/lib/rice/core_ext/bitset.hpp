class Bitset {
  public:

  Vbool array;

  explicit Bitset(size_t count):
    array(count, false) {
  }

  explicit Bitset(const Vbool & bools):
    array(bools) {
  }

  Bitset() = delete;

  auto operator[](size_t i)       { return array.at(i); }
  bool operator[](size_t i) const { return array.at(i); }
  auto front()       { return array.front(); }
  bool front() const { return array.front(); }
  auto back()        { return array.back(); }
  bool back()  const { return array.back(); }
  auto size()  const { return array.size(); }

  auto to_s() const {
    size_t count = size();
    std::string bits(count, '0');
    bool bit;
    for (size_t i = 0; i < count; ++i) if ((bit = array[i])) bits[i] = '1';
    return bits;
  }
};
