require './test/rails_helper'

class TimeTest < ActiveSupport::TestCase
  test '#rotations' do
    today = Time.utc(2000, 1, 3)
    expected = %w(
      2000_01_03
      2000_01_02
      2000_01_01
      1999_12_31
      1999_12_30
      1999_12_27
      1999_12_20
      1999_12_01
    )
    assert_equal expected, today.rotations(days: 5, weeks: 3, months: 2)
    assert_rotations(today += 1.day, expected, add: '2000_01_04', remove: ['1999_12_30'])
    assert_rotations(today += 1.day, expected, add: '2000_01_05', remove: ['1999_12_31'])
    assert_rotations(today += 1.day, expected, add: '2000_01_06', remove: [])
    assert_rotations(today += 1.day, expected, add: '2000_01_07', remove: ['2000_01_02'])
    assert_rotations(today += 1.day, expected, add: '2000_01_08', remove: [])
    assert_rotations(today += 1.day, expected, add: '2000_01_09', remove: ['2000_01_04'])
    assert_rotations(today += 1.day, expected, add: '2000_01_10', remove: ['2000_01_05', '1999_12_20'])
    assert_rotations(today += 1.day, expected, add: '2000_01_11', remove: ['2000_01_06'])
    assert_rotations(today += 1.day, expected, add: '2000_01_12', remove: ['2000_01_07'])
    assert_rotations(today += 1.day, expected, add: '2000_01_13', remove: ['2000_01_08'])
    assert_rotations(today += 1.day, expected, add: '2000_01_14', remove: ['2000_01_09'])
    assert_rotations(today += 1.day, expected, add: '2000_01_15', remove: [])
    assert_rotations(today += 1.day, expected, add: '2000_01_16', remove: ['2000_01_11'])
    assert_rotations(today += 1.day, expected, add: '2000_01_17', remove: ['2000_01_12', '1999_12_27'])
    assert_rotations(today += 1.day, expected, add: '2000_01_18', remove: ['2000_01_13'])
    assert_rotations(today += 1.day, expected, add: '2000_01_19', remove: ['2000_01_14'])
    assert_rotations(today += 1.day, expected, add: '2000_01_20', remove: ['2000_01_15'])
    assert_rotations(today += 1.day, expected, add: '2000_01_21', remove: ['2000_01_16'])
    assert_rotations(today += 1.day, expected, add: '2000_01_22', remove: [])
    assert_rotations(today += 1.day, expected, add: '2000_01_23', remove: ['2000_01_18'])
    assert_rotations(today += 1.day, expected, add: '2000_01_24', remove: ['2000_01_19', '2000_01_03'])
    assert_rotations(today += 1.day, expected, add: '2000_01_25', remove: ['2000_01_20'])
    assert_rotations(today += 1.day, expected, add: '2000_01_26', remove: ['2000_01_21'])
    assert_rotations(today += 1.day, expected, add: '2000_01_27', remove: ['2000_01_22'])
    assert_rotations(today += 1.day, expected, add: '2000_01_28', remove: ['2000_01_23'])
    assert_rotations(today += 1.day, expected, add: '2000_01_29', remove: [])
    assert_rotations(today += 1.day, expected, add: '2000_01_30', remove: ['2000_01_25'])
    assert_rotations(today += 1.day, expected, add: '2000_01_31', remove: ['2000_01_26', '2000_01_10'])
    assert_rotations(today += 1.day, expected, add: '2000_02_01', remove: ['2000_01_27', '1999_12_01'])
    assert_rotations(today += 1.day, expected, add: '2000_02_02', remove: ['2000_01_28'])

    today = Time.utc(2000, 1, 3)
    assert_rotations today, ['2000_01_03'], days: 1, weeks: 0, months: 0
    assert_rotations today, ['2000_01_03'], days: 1, weeks: 1, months: 0
    assert_rotations today, ['2000_01_03', '2000_01_01'], days: 1, weeks: 1, months: 1
    assert_rotations(today += 1.day, ['2000_01_04', '2000_01_03', '2000_01_01'], days: 1, weeks: 1, months: 1)
  end

  private

  def assert_rotations(today, expected, add: nil, remove: [], days: 5, weeks: 3, months: 2)
    expected.unshift(add) if add
    remove.each{ |day| expected.delete(day) }
    assert_equal expected, today.rotations(days: days, weeks: weeks, months: months)
  end
end
