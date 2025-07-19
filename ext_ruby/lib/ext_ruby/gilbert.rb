### References
# https://github.com/jakubcerveny/gilbert
class Gilbert
  CACHE_DIR = './tmp/cache/gilbert'

  def self.curve(*x, cache: true)
    if cache
      list ||= ((@list ||= {})[x] ||= cache_read(*x))
      return list if list
    end
    unless (dims = x.size).in? [2, 3]
      raise "unsupported number of dimensions [#{dims}], only 2 or 3 allowed"
    end
    axes = dims.times.to_a
    x0 = [0] * dims
    axes.each do |i|
      rest = axes.except(i)
      if rest.all?{ |j| x[i] >= x[j] }
        list = build x0, *[i, *rest].map{ |j| x0.dup.tap{ |xn| xn[j] = x[j] } }
        break
      end
    end
    if cache
      cache_write(*x, list)
      @list[x] = list
    end
    list
  end

  def self.grid(...)
    curve(...).each_with_object([]).with_index do |(x0, grid), i|
      col = grid
      *x0, xn = x0
      x0.each do |x|
        col = (col[x] ||= [])
      end
      col[xn] = i
    end
  end

  def self.clear_cache
    FileUtils.rm_rf Dir.glob("#{CACHE_DIR}/*.csv")
  end

  def self.cache_write(*x, list)
    CSV.open("#{CACHE_DIR}/#{x.join('-')}.csv", "w") do |csv|
      Thread.pass while (locked ||= csv.flock(File::LOCK_EX | File::LOCK_NB) == false)
      list.each{ |row| csv << row } unless locked
      csv << Array.new(x.size, -1) # completion marker
      csv.flock(File::LOCK_UN)
    end
  end
  private_class_method :cache_write

  def self.cache_read(*x)
    FileUtils.mkdir_p CACHE_DIR
    file = "#{CACHE_DIR}/#{x.join('-')}.csv"
    return unless File.exist? file
    list = []
    CSV.foreach(file, converters: [:integer]){ |row| list << row }
    return unless list.pop == Array.new(x.size, -1)
    list
  end
  private_class_method :cache_read

  def self.build(x0, *x, list: [])
    dims = x0.size
    grid = [x]
    size = [grid[0].map(&:sum).map(&:abs)]
    step = grid[0].map{ |row| row.map(&:sign) }

    # trivial single axis fill
    axes = dims.times.to_a
    axes.each do |i|
      if axes.except(i).all?{ |j| size[0][j] == 1 }
        size[0][i].times do
          list << x0
          x0 = x0.add(step[i])
        end
        return list
      end
    end

    grid << grid[0].map{ |row| row.map(&:/.with(2)) }
    size << grid[1].map(&:sum).map(&:abs)

    # prefer even steps
    axes.each do |i|
      if (size[1][i] % 2) != 0 && size[0][i] > 2
        grid[1][i] = grid[1][i].add(step[i])
      end
    end

    case dims
    when 2
      if 2*size[0][0] > 3*size[0][1] # split in x[0] only
        build x0, grid[1][0], grid[0][1], list: list
        build x0.add(grid[1][0]), grid[0][0].sub(grid[1][0]), grid[0][1], list: list
      else # split in all x
        build x0, grid[1][1], grid[1][0], list: list
        build x0.add(grid[1][1]), grid[0][0], grid[0][1].sub(grid[1][1]), list: list
        build x0.add(grid[0][0].sub(step[0]), grid[1][1].sub(step[1])), grid[1][1].neg, grid[0][0].sub(grid[1][0]).neg, list: list
      end
    when 3
      if 2*size[0][0] > 3*size[0][1] && 2*size[0][0] > 3*size[0][2] # split in x[0] only
        build x0, grid[1][0], grid[0][1], grid[0][2], list: list
        build x0.add(grid[1][0]), grid[0][0].sub(grid[1][0]), grid[0][1], grid[0][2], list: list
      elsif 3*size[0][1] > 4*size[0][2] # split in x[0] and x[1] only
        build x0, grid[1][1], grid[0][2], grid[1][0], list: list
        build x0.add(grid[1][1]), grid[0][0], grid[0][1].sub(grid[1][1]), grid[0][2], list: list
        build x0.add(grid[0][0].sub(step[0]), grid[1][1].sub(step[1])), grid[1][1].neg, grid[0][2], grid[0][0].sub(grid[1][0]).neg, list: list
      elsif 3*size[0][2] > 4*size[0][1] # split in x[0] and x[2] only
        build x0, grid[1][2], grid[1][0], grid[0][1], list: list
        build x0.add(grid[1][2]), grid[0][0], grid[0][1], grid[0][2].sub(grid[1][2]), list: list
        build x0.add(grid[0][0].sub(step[0]), grid[1][2].sub(step[2])), grid[1][2].neg, grid[0][0].sub(grid[1][0]).neg, grid[0][1], list: list
      else # split in all x
        build x0, grid[1][1], grid[1][2], grid[1][0], list: list
        build x0.add(grid[1][1]), grid[0][2], grid[1][0], grid[0][1].sub(grid[1][1]), list: list
        build x0.add(grid[1][1].sub(step[1]), grid[0][2].sub(step[2])), grid[0][0], grid[1][1].neg, grid[0][2].sub(grid[1][2]).neg, list: list
        build x0.add(grid[0][0].sub(step[0]), grid[1][1], grid[0][2].sub(step[2])), grid[0][2].neg, grid[0][0].sub(grid[1][0]).neg, grid[0][1].sub(grid[1][1]), list: list
        build x0.add(grid[0][0].sub(step[0]), grid[1][1].sub(step[1])), grid[1][1].neg, grid[1][2], grid[0][0].sub(grid[1][0]).neg, list: list
      end
    else
      raise "unsupported number of dimensions [#{dims}], only 2 or 3 allowed"
    end
  end
  private_class_method :build
end
