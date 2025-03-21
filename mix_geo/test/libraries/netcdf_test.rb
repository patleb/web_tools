require './test/test_helper'
require './app/libraries/ext'
Rice.require_overrides

class NetCDFTest < ActiveSupport::TestCase
  let(:path){ dir.join('data.nc') }
  let(:dir){ dir = Pathname.new('./tmp/test/netcdf'); dir.mkdir_p; dir }

  before do
    path.delete(false)
  end

  test '#open, #write, #read' do
    assert(NetCDF::File.open(path, 'w') do |f|
      refute f.closed?

      f.create_dim :n
      f.create_dim :x, 2
      f.create_dim :y, 4
      t = f.create_dim :t
      f.create_dim 'team_i', 3
      f.create_dim 'team_name', 6
      assert t.unlimited?
      assert t.size == 0

      f.write_att :srid, 4326
      f.write_att :year,    Numo::Int16[2000]
      f.write_att :sizes,   Numo::UInt64[20, 30.9]
      f.write_att 'center', Numo::DFloat[50.7, -120.8]

      n = f.create_var :none, :UInt8, [:n, :y, :x]
      f.create_var :event, NetCDF::Type::SFloat, [:team_i, :t]
      f.create_var :heat,  NetCDF::Type::SFloat, [:y, :x], fill_value: Float::NAN
      f.create_var :team, 'String', ['team_i', 'team_name']
      f.create_var :time, 'UInt64', [:t]
      f.create_var 'lon', :DFloat, :x, fill_value: Numo::DFloat[Float::INFINITY]
      f.create_var 'lat', :DFloat, :y, fill_value: -Float::INFINITY
      assert_equal 0, n.shape.reduce(&:*)

      f.write_att :type, 'results', var: :event
      f.write_att :groups, Numo::UInt8[10, 23], var: :team

      assert_equal [0, 2, 4, 0, 3, 6], f.dims.values.map(&:size)
      assert_equal [4, 1, 2, 2], f.atts.values.map(&:size)

      f.write_att 'NA', 'nothing'
      assert_equal 5, f.atts.size
      f.delete_att 'NA'
      assert_equal 4, f.atts.size
      f.write_att 'NA', 'nothing', var: :event
      assert_equal 2, f.vars[:event].atts.size
      f.delete_att 'NA', var: :event
      assert_equal 1, f.vars[:event].atts.size

      assert_equal '4326',         f.read_att(:srid)
      assert_equal [2000],         f.read_att(:year)
      assert_equal [20, 30.0],     f.read_att(:sizes)
      assert_equal [50.7, -120.8], f.read_att(:center)
      assert_equal 'results',      f.read_att(:type, var: :event)
      assert_equal [10, 23],       f.read_att(:groups, var: :team)

      assert f.fill_value(:heat).nan?
      assert f.fill_value(:time).nil?
      assert f.fill_value(:lon).infinite?
      assert f.fill_value(:lon).positive?
      assert f.fill_value(:lat).infinite?
      assert f.fill_value(:lat).negative?
    end.closed?)

    e1 = Numo::SFloat.new(1, 3).seq
    e2 = Numo::SFloat.new(2, 3).seq
    h1 = Numo::SFloat.ones(3, 1)
    h2 = Numo::SFloat.ones(2, 1)

    assert(NetCDF::File.open(path, 'a') do |f|
      refute f.closed?

      f.write :event, e1, start: [0, 7]
      f.write :event, e2, start: [1, 2], stride: [1, 2]
      f.write :heat, h1
      f.write :heat, h2, start: [1, 1], stride: [2, 1]
      f.write :team, 'first'
      f.write :team, ['2nd'], start: 2
      f.write :time, Numo::UInt64[0...10]
      f.write :lon, Numo::DFloat[10.0]
      f.write :lat, Numo::DFloat[-100]
    end.closed?)

    assert(NetCDF::File.open(path) do |f|
      refute f.closed?

      assert_equal 0, f.vars[:none].shape.reduce(&:*)
      h = Numo::SFloat.ones(f.vars[:heat].shape.to_a)
      h[0, 1] = Float::NAN
      h[2, 1] = Float::NAN
      h[3, 0] = Float::NAN
      assert_equal h.to_a.to_s, f.read(:heat).to_a.to_s
      assert_equal e1, f.read(:event, start: [0, 7], count: e1.shape)
      assert_equal e2, f.read(:event, start: [1, 2], count: e2.shape, stride: [1, 2])
      assert_equal ['first', '2nd'], f.read(:team, count: 2, stride: 2).to_a
      assert_equal [2, 4, 6, 8],     f.read(:time, start: 2, count: 4, stride: 2).to_a
      assert_equal 10.0,             f.read(:lon, at: 0)
      assert_equal [-100.0] + [-Float::INFINITY] * 3, f.read(:lat).to_a
    end.closed?)
  end
end
