module Postgis
  class SpatialRefSys < ActiveRecord::Base
    extend ActiveSupport::Testing::Stream

    class UnexpectedVertex < ::StandardError; end

    pyimport :numpy
    pyimport :pyproj
    pyimport :psycopg2
    pyimport :rasterio
    pyfrom   'rasterio.warp', import: [:transform, :transform_bounds, :reproject]
    pyfrom   'rasterio.control', import: [:GroundControlPoint]

    CF_KEYS_ALIASES = { # pyproj typo errors
      false_easting: :fase_easting,
      false_northing: :fase_northing,
    }
    CF_KEYS = %i(
      grid_mapping_name
      standard_parallel
      longitude_of_central_meridian
      latitude_of_projection_origin
      false_easting
      false_northing
      semi_major_axis
      inverse_flattening
    )
    CLOSEPOLY = 79
    LINETO = 2
    MOVETO = 1

    self.primary_key = :srid

    scope :from_projection, -> (projection) { where(crs_for(projection)) }

    def self.find_by_projection(projection)
      from_projection(projection).order(:srid).take
    end

    def self.projection_exists?(projection)
      from_projection(projection).exists?
    end

    def self.create_projection!(srid, projection)
      create! srid: srid, auth_name: 'none', auth_srid: srid, **crs_for(projection)
    end

    def self.crs_for(projection)
      cf = projection.symbolize_keys.slice(*CF_KEYS).transform_keys{ |k| CF_KEYS_ALIASES[k] || k }
      crs = pyproj.crs.CRS.from_cf(cf, true)
      { srtext: crs.to_wkt, proj4text: silence_stream(STDERR){ crs.to_proj4 } }
    end
    delegate :crs_for, to: :class

    def self.proj4(srid)
      find(srid).proj4
    end

    # EPSG:3857 bounds for postgis cartesian coordinates approximately ±20037508.34 or exactly ±20037508.342789
    def self.py_reproject(srid, source, src_bounds, src_nodata: nil, dst_nodata: nil, fill_ratio: nil)
      return [source, src_bounds] if srid == 4326
      src_crs, dst_crs = proj4(srid), 'epsg:4326'
      src_shape = source.shape.to_a
      dst_shape = fill_ratio ? src_shape.map{ |size| (size * fill_ratio).ceil } : src_shape
      dst_bounds = transform_bounds(src_crs, dst_crs, *src_bounds).to_a
      src_transform, dst_transform = [[src_shape, src_bounds], [dst_shape, dst_bounds]].map do |shape, (left, top, right, bottom)|
        rasterio.transform.from_gcps([
          GroundControlPoint.new(0, 0, left, top),
          GroundControlPoint.new(*shape, right, bottom),
        ])
      end
      dst = numpy.zeros(dst_shape)
      options = { src_crs: src_crs, src_transform: src_transform, destination: dst, dst_crs: dst_crs, dst_transform: dst_transform }
      options[:src_nodata] = src_nodata if src_nodata
      reproject(source, **options)
      numpy.nan_to_num(dst, copy: false, nan: dst_nodata) if src_nodata&.nan? && dst_nodata
      [dst, dst_bounds]
    end

    # can't use pyproj for custom srid --> https://lists.osgeo.org/pipermail/proj/2019-May/008589.html
    def self.py_transform(srid, x, y)
      return [x, y] if srid == 4326
      case x
      when Numeric
        transform(proj4(srid), 'epsg:4326', [x], [y]).to_a.map(&:first)
      when Array
        if x.size != y.size
          y0 = [y[0]] * x.size
          x0 = [x[0]] * y.size
          x = transform(proj4(srid), 'epsg:4326', x, y0).to_a.first
          y = transform(proj4(srid), 'epsg:4326', x0, y).to_a.last
          [x, y]
        else
          transform(proj4(srid), 'epsg:4326', x, y).to_a
        end
      else
        py_transform(srid, x.to_a, y.to_a)
      end
    end

    def self.py_contour(source, x_axis, y_axis, levels, sql: false, debug: false)
      contours = if debug
        py_plot.contourf(x_axis, y_axis, source, levels, antialiased: false)
      else
        silence_stream(STDERR){ py_plot.contourf(x_axis, y_axis, source, levels, antialiased: false) }
      end
      contours.collections.each_with_index do |line_collection, level_i|
        line_collection.get_paths.each do |lines|
          points = lines.vertices
          polygons = lines.codes.to_list.each_with_object([]).with_index do |(code, polygons), point_i|
            case code.to_i
            when MOVETO
              polygons << [points[point_i]]
            when LINETO, CLOSEPOLY
              polygons[-1] << points[point_i]
            else
              raise UnexpectedVertex
            end
          end
          polygons.reject!{ |polygon| polygon.size <= 3 }
          next if polygons.empty?
          if sql
            polygons.map!{ |polygon| polygon.map!{ |point| point.to_list.to_a.join(' ') } }
            polygons.map!{ |polygon| polygon.join(',') }
            polygons.map!{ |polygon| "ST_GeomFromText('LINESTRING(#{polygon})', 4326)" }
            if polygons.size == 1
              contour = "ST_MakePolygon(#{polygons[0]})"
            else
              contour = "ST_MakePolygon(#{polygons[0]}, ARRAY[#{polygons[1..-1].join(',')}])"
            end
            yield(levels[level_i].to_sql, contour)
          else
            yield(levels[level_i], polygons)
          end
        end
      end
    end

    def self.py_plot
      @py_plot ||= begin
        require 'matplotlib/pyplot'
        Matplotlib::Pyplot
      end
    end

    def self.py_exec_query(sql, *args)
      py_cursor.execute(sql, args)
    ensure
      py_connection.commit
    end

    def self.py_connection_close
      py_cursor.close
      py_connection.close
      @py_cursor = @py_connection = nil
    end

    def self.py_cursor
      @py_cursor ||= py_connection.cursor
    end

    def self.py_connection
      Setting.db do |host, port, database, username, password|
        @py_connection ||= psycopg2.connect("dbname='#{database}' user='#{username}' host=#{host} password='#{password}' port=#{port}")
      end
    end

    def update_projection!(projection)
      update! crs_for(projection)
    end

    def proj4
      if auth_name == 'none'
        proj4text.split('+').reject(&:blank?).map{ |kv| kv.include?('=') ? kv.split('=') : [kv, true] }.to_h
          .symbolize_keys!.transform_values!{ |v| v.is_a?(String) ? v.strip.cast_self : v }
      else
        { init: "epsg:#{srid}" }
      end
    end
  end
end
