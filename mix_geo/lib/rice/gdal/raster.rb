module GDAL
  Raster.class_eval do
    self::Transform.class_eval do
      module self::WithOverrides
        def shape
          super.to_a
        end
      end
      prepend self::WithOverrides
    end

    module self::WithOverrides
      def initialize(z, *x01_y01, x: nil, y: nil, proj: nil, **proj4)
        proj = GDAL.proj4text(**proj4) unless proj || proj4.empty?
        x01_y01 = self.class.x01_y01(x, y, proj) if x01_y01.empty?
        super(z, z.type, x01_y01, proj&.to_s)
      end

      def shape
        super.to_a
      end

      def x
        super.to_a
      end

      def y
        super.to_a
      end

      def reproject(proj = nil, fill_value: nil, compact: nil, memoize: nil, **proj4)
        proj = proj ? proj.to_s : GDAL.proj4text(**proj4)
        super(proj, fill_value, compact, memoize)
      end
    end
    prepend self::WithOverrides

    def self.x01_y01(x, y, proj)
      x01_y01, axis = [], [x, y]
      orientation(proj).each_with_index do |sign, i|
        axis_i = axis[i]
        v0, v1 = axis_i[0], axis_i[1]
        if sign.negative?
          v0, v1 = axis_i[-1], axis_i[-2] if v0 < v1
        else
          v0, v1 = axis_i[-1], axis_i[-2] if v0 > v1
        end
        x01_y01[0 + 2*i] = v0
        x01_y01[1 + 2*i] = v1
      end
      x01_y01
    end

    def x01_y01
      [x0, x0 + dx, y0, y0 + dy]
    end

    def _reproject_(proj = nil, fill_value: nil, compact: nil, memoize: nil, **proj4)
      proj = proj ? proj.to_s : GDAL.proj4text(**proj4)
      tf = transform_for(proj, compact, memoize)
      nearest = _nearest_for_(tf, memoize)
      width, height, x0, y0, dx, dy = tf.width, tf.height, tf.x0, tf.y0, tf.dx, tf.dy
      src_data = z
      src_fill_value = src_data.fill_value
      fill_value = src_fill_value if fill_value.nil?
      dst_data = Tensor.build(type, height, width, fill_value: fill_value)
      src_fill_value_nan = src_fill_value.nan?
      height.times do |j|
        width.times do |i|
          if (point = nearest[j][i]).nil?
            dst_data[j, i] = fill_value
          else
            value = src_data[point]
            if src_fill_value_nan
              dst_data[j, i] = value.nan? ? fill_value : value
            else
              dst_data[j, i] = (value == src_fill_value) ? fill_value : value
            end
          end
        end
      end
      self.class.new(dst_data, x0, x0 + dx, y0, y0 + dy, proj: proj)
    end

    private :transform_for

    private

    def _nearest_for_(tf, memoize = nil)
      return _cached_nearest_for_(tf) if memoize
      mesh, width, height, x0, y0, dx, dy, rx, ry = tf.mesh.to_a, tf.width, tf.height, tf.x0, tf.y0, tf.dx, tf.dy, tf.rx, tf.ry
      mesh_points = Array.new(height){ Array.new(width){ Set.new } }
      mesh.each_with_index do |(x, y), point|
        j = ((y - y0) / dy).round
        i = ((x - x0) / dx).round
        mesh_points[j][i] << point
      end
      nearest = Array.new(height){ Array.new(width) }
      max_rx, max_ry = (dx * rx).abs, (dy * ry).abs
      yj = y0
      height.times do |j|
        xi = x0
        width.times do |i|
          points = Set.new
          (j - ry).upto(j + ry) do |box_j|
            next if box_j  < 0 || box_j >= height
            (i - rx).upto(i + rx) do |box_i|
              next if box_i < 0 || box_i >= width
              points.merge(mesh_points[box_j][box_i])
            end
          end
          distances = points.select_map do |point|
            x, y = mesh[point]
            next if (dist_x = (x - xi).abs) > max_rx
            next if (dist_y = (y - yj).abs) > max_ry
            dist = dist_x * dist_x + dist_y * dist_y
            [dist, point]
          end
          distances.sort!
          _distance, point = distances.first
          nearest[j][i] = point
          xi += dx
        end
        yj += dy
      end
      nearest
    end

    def _cached_nearest_for_(tf)
      key = tf.cache_key(self)
      unless (nearest = (@@nearest_cache ||= {})[key])
        nearest = (@@nearest_cache[key] = _nearest_for_(tf))
      end
      nearest
    end
  end
end
