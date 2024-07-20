require './test/spec_helper'

class ObjectTry
  class << self
    def true
      true
    end

    def truthy
      'truthy'
    end

    def false
      false
    end

    def nil
      nil
    end
  end
end

class Object::TryTest < Minitest::TestCase
  test '#true?' do
    assert_equal true, ObjectTry.true?(:true)
    assert_equal false, ObjectTry.true?(:truthy)
    assert_equal false, ObjectTry.true?(:false)
    assert_equal false, ObjectTry.true?(:nil)
    assert_equal false, ObjectTry.true?(:missing)
  end

  test '#truthy?' do
    assert_equal true, ObjectTry.truthy?(:true)
    assert_equal true, ObjectTry.truthy?(:truthy)
    assert_equal false, ObjectTry.truthy?(:false)
    assert_equal false, ObjectTry.truthy?(:nil)
    assert_equal false, ObjectTry.truthy?(:missing)
  end

  test '#false?' do
    assert_equal false, ObjectTry.false?(:true)
    assert_equal false, ObjectTry.false?(:truthy)
    assert_equal true, ObjectTry.false?(:false)
    assert_equal false, ObjectTry.false?(:nil)
    assert_equal false, ObjectTry.false?(:missing)
  end

  test '#falsy?' do
    assert_equal false, ObjectTry.falsy?(:true)
    assert_equal false, ObjectTry.falsy?(:truthy)
    assert_equal true, ObjectTry.falsy?(:false)
    assert_equal true, ObjectTry.falsy?(:nil)
    assert_equal true, ObjectTry.falsy?(:missing)
  end

  test '#nil_or_true?' do
    assert_equal true, ObjectTry.nil_or_true?(:true)
    assert_equal false, ObjectTry.nil_or_true?(:truthy)
    assert_equal false, ObjectTry.nil_or_true?(:false)
    assert_equal true, ObjectTry.nil_or_true?(:nil)
    assert_equal true, ObjectTry.nil_or_true?(:missing)
  end

  test '#nil_or_truthy?' do
    assert_equal true, ObjectTry.nil_or_truthy?(:true)
    assert_equal true, ObjectTry.nil_or_truthy?(:truthy)
    assert_equal false, ObjectTry.nil_or_truthy?(:false)
    assert_equal true, ObjectTry.nil_or_truthy?(:nil)
    assert_equal true, ObjectTry.nil_or_truthy?(:missing)
  end

  test '#nil_or_false?' do
    assert_equal false, ObjectTry.nil_or_false?(:true)
    assert_equal false, ObjectTry.nil_or_false?(:truthy)
    assert_equal true, ObjectTry.nil_or_false?(:false)
    assert_equal true, ObjectTry.nil_or_false?(:nil)
    assert_equal true, ObjectTry.nil_or_false?(:missing)
  end

  test '#nil_or_falsy?' do
    assert_equal false, ObjectTry.nil_or_falsy?(:true)
    assert_equal false, ObjectTry.nil_or_falsy?(:truthy)
    assert_equal true, ObjectTry.nil_or_falsy?(:false)
    assert_equal true, ObjectTry.nil_or_falsy?(:nil)
    assert_equal true, ObjectTry.nil_or_falsy?(:missing)
  end
end
