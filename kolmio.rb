# Triangle puzzle
# Stephen Sykes December 2015

RESULT_FILE_NAME = "result_#.png"
STEP_FILE_NAME = "steps.json"

require 'json'
require 'oily_png'

class Side
  attr_reader :is_top
  attr_reader :name

  def initialize(name, is_top)
    @name = name
    @is_top = is_top
  end

  def matches(other)
    other.name == @name && other.is_top != @is_top
  end
  
  def is_legal_for_outer_edge
    !@is_top && @name == "fox" ||
      @is_top && @name == "bambi" ||
      !@is_top && @name == "raccoon"
  end

  def inspect
    "#{name} #{@is_top ? "top" : "bottom"}"
  end
end

class Triangle
  attr_reader :sides
  attr_reader :rotation
  attr_reader :number
  
  def initialize(sides, n)
    @sides = sides
    @number = n
    @description = "P#{n}"
    @rotation = 0
  end

  def rotate
    @sides = sides.rotate
    @rotation = (@rotation + 1) % 3
  end

  def inspect
    @description
  end

  def index
    @description[1].to_i - 1
  end
end

class Outputter
  COORDS = [
    [302, 0],
    [151, 260],
    [302, 260],
    [453, 260],
    [0, 520],
    [151, 520],
    [302, 520],
    [453, 520],
    [604, 520]
  ]

  def initialize
    @p_images = []
    0.upto(8) do |n|
      @p_images[n] = []
      0.upto(2) do |m|
        png_name = "P#{n + 1}_#{m}.png"
        @p_images[n][m] = ChunkyPNG::Image.from_datastream(ChunkyPNG::Datastream.from_file(png_name))
      end
    end
    
    @result_count = 0
  end

  def output(result)
    @result_count += 1
    puts result.inspect
    return
    img = ChunkyPNG::Image.new(904, 779, ChunkyPNG::Color::WHITE)
    result.each_with_index do |triangle, pos_index|
      upside_down = [2,5,7].include?(pos_index)
      rotation = triangle.rotation
      rotation = (rotation + 1) % 3 if upside_down
      add_image = @p_images[triangle.index][rotation]
      coords = COORDS[pos_index]
      add_image = add_image.rotate_180 if upside_down
      img.compose!(add_image, coords[0], coords[1])
    end
    img.save(RESULT_FILE_NAME.gsub(/#/, @result_count.to_s))
  end

end

class Solver
  # Note that the outer edge must be composed of 4 x fox_b, 4 x bambi_t and 1 x raccoon_b
  TRIANGLE_DEFS = [
    [:fox_t, :fox_b, :bambi_t],
    [:bambi_t, :fox_b, :raccoon_b],
    [:bambi_t, :fox_b, :fox_t],
    [:bambi_t, :bambi_b, :fox_b],
    [:bambi_t, :raccoon_b, :bambi_b],
    [:raccoon_b, :fox_b, :raccoon_t],
    [:fox_b, :raccoon_t, :fox_t],
    [:raccoon_t, :bambi_t, :raccoon_b],
    [:fox_b, :bambi_b, :bambi_t]
  ]

  CONDITIONS = [
    # edges that must match [pos1, edge1, pos2, edge2]
    [0,2,2,0],
    [1,1,2,2],
    [1,2,5,0],
    [2,1,3,0],
    [3,2,7,0],
    [4,1,5,2],
    [5,1,6,0],
    [6,1,7,2],
    [7,1,8,0]
  ]

  OUTER_EDGES = [
    [0,1],
    [0],
    [],
    [1],
    [0,2],
    [],
    [2],
    [],
    [1,2]
  ]

  def initialize
    make_triangles
    
    @solve_count = 0
    @steps = []
  end

  def run
    outputter = Outputter.new

    0.upto(8) do |n|
      triangle = @triangles[n]
      result = tryrotate(triangle, 0) { solve([triangle,nil,nil,nil,nil,nil,nil,nil,nil], 0) }
      outputter.output(result) if result
    end

    File.open(STEP_FILE_NAME, "w") {|f| f.write(@steps.to_json)}
    puts "#{@solve_count} steps"
  end

  def make_triangles
    n = 0
    @triangles = TRIANGLE_DEFS.collect do |sides|
      figures = sides.collect do |side|
        is_top = side.to_s =~ /_t/ ? true : false
        name = side.to_s[/[^_]*/]
        Side.new(name, is_top)
      end

      n += 1
      Triangle.new(figures, n)
    end  
  end


  def tryrotate(triangle, pos)
    3.times do
      triangle.rotate
      next unless canplace(triangle, pos)
      result = yield()
      return result if result
    end
    return false
  end

  def canplace(triangle, pos)
    OUTER_EDGES[pos].each do |edge|
      return false unless triangle.sides[edge].is_legal_for_outer_edge
    end
    return true
  end

  def solve(placings, level)
    @steps << placings.collect {|triangle| triangle ? [triangle.number, triangle.rotation] : nil}
    @solve_count += 1

    return placings if CONDITIONS.size == level

    condition = CONDITIONS[level]
    pos1, side1, pos2, side2 = condition

    if placings[pos1] && placings[pos2]
      if placings[pos1].sides[side1].matches(placings[pos2].sides[side2])
        solve(placings, level + 1)
      else
        false
      end
    else
      unfilled_pos = [pos1, pos2].detect{|pos| !placings[pos]}

      unused = @triangles - placings
      unused.each do |triangle|
        placings[unfilled_pos] = triangle

        tryrotate(triangle, unfilled_pos) do
          if placings[pos1].sides[side1].matches(placings[pos2].sides[side2])
            solution = solve(placings, level + 1)
            return solution if solution
          end
        end
      end
      placings[unfilled_pos] = nil
      false
    end
  end

end

Solver.new.run
