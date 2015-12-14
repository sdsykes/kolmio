# MEGAKOLMIO Triangle puzzle
# Stephen Sykes December 2015

# Usage: ruby kolmio.rb [webgen]
# Running without the webgen parameter just produces the
# results in the format specified by the competition rules.
# Adding the webgen parameter enables output of results images
# and the steps file needed for the web page. Generating the
# png files is very slow, so this takes much longer to run.

RESULT_FILE_NAME = "images/result_#.png"
STEP_FILE_NAME = "steps.json"

require 'json'
require 'oily_png'

class Side
  attr_reader :sym
  attr_reader :is_top
  attr_reader :name

  def initialize(sym)
    @sym = sym
    @is_top = sym.to_s =~ /_t/ ? true : false
    @name = sym.to_s[/[^_]*/]
  end

  def matches(other)
    other.name == @name && other.is_top != @is_top
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
        png_name = "images/P#{n + 1}_#{m}.png"
        @p_images[n][m] = ChunkyPNG::Image.from_datastream(ChunkyPNG::Datastream.from_file(png_name))
      end
    end
    
    @result_count = 0
  end

  def output(result, options)
    @result_count += 1
    puts result.inspect
    return unless options[:webgen]
    
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
  
  # Note that the outer edge must be composed of 4 x fox_b, 4 x bambi_t and 1 x raccoon_b
  OUTER_EDGE_COMPOSITION = [
    :fox_b, :fox_b, :fox_b, :fox_b, :bambi_t, :bambi_t, :bambi_t, :bambi_t, :raccoon_b
  ]

  def initialize
    make_triangles
    
    @solve_count = 0
    @steps = []
  end

  def run(options = {})
    outputter = Outputter.new

    0.upto(8) do |n|
      triangle = @triangles[n]
      unused_outer_edges = OUTER_EDGE_COMPOSITION.dup
      result = tryrotate(triangle, 0, unused_outer_edges, []) do |_unused_outer_edges|
        solve([triangle,nil,nil,nil,nil,nil,nil,nil,nil], 0, _unused_outer_edges)
      end
      outputter.output(result, options) if result
    end
    
    if options[:webgen]
      File.open(STEP_FILE_NAME, "w") {|f| f.write(@steps.to_json)}
    end
    # For info, solutions were found in @solve_count steps
  end

  def make_triangles
    n = 0
    @triangles = TRIANGLE_DEFS.collect do |sides|
      figures = sides.collect do |side|
        Side.new(side)
      end

      n += 1
      Triangle.new(figures, n)
    end  
  end

  def tryrotate(triangle, pos, unused_outer_edges, placings)
    3.times do
      triangle.rotate
      unused_or_false = canplace(triangle, pos, unused_outer_edges)
      next unless unused_or_false
      next unless have_enough_outer_edges(triangle, unused_or_false, placings)
      result = yield(unused_or_false)
      return result if result
    end
    return false
  end

  # This is an optimisation, due to the observation that only certain pictures can appear
  # on the outer edge of the megakolmio. It returns false if the triangle cannot be placed
  # in this position according to that rule. Otherwise it returns the remaining unused
  # outer edges.
  def canplace(triangle, pos, unused_outer_edges)
    edge_syms = OUTER_EDGES[pos].collect {|edge_index| triangle.sides[edge_index].sym}
    unused = unused_outer_edges.dup
    edge_syms.each do |edge_sym|
      return false unless unused.include?(edge_sym)
      unused.delete_at(unused.index(edge_sym))
    end
    return unused
  end

  # This condition returns true if after accounting for the used triangle pieces, and
  # the one passed in the triangle argument, there are enough suitable outer edges remaining for
  # the puzzle to be completed.
  def have_enough_outer_edges(triangle, unused_outer_edges, placings)
    unused_triangles = @triangles - placings - [triangle]
    sides_remaining = unused_triangles.inject([]) {|arr, triangle| arr += triangle.sides.collect{|side| side.sym}}

    unused_outer_edges.each do |unused_side|
      index = sides_remaining.index(unused_side)
      return false unless index
      sides_remaining.delete_at(index)
    end
    return true
  end

  # This does the main work, recursively.
  # The level parameter relates to the CONDITIONS - when all conditions are met, 
  # then a solution is found.
  #
  # The unused_outer_edges parameter enables an optimisation that elimiates certain branches early
  # because we know exactly what pictures are used on the outside of the triangle.
  def solve(placings, level, unused_outer_edges)
    @steps << placings.collect {|triangle| triangle ? [triangle.number, triangle.rotation] : nil}
    @solve_count += 1

    return placings if CONDITIONS.size == level

    condition = CONDITIONS[level]
    pos1, side1, pos2, side2 = condition

    # If the two positions alread have pieces in them then check the condition
    if placings[pos1] && placings[pos2]
      if placings[pos1].sides[side1].matches(placings[pos2].sides[side2])
        solve(placings, level + 1, unused_outer_edges)
      else
        false
      end
    else
      # One position was unfilled - find a piece that fits
      unfilled_pos = [pos1, pos2].detect{|pos| !placings[pos]}

      unused = @triangles - placings
      unused.each do |triangle|
        placings[unfilled_pos] = triangle

        tryrotate(triangle, unfilled_pos, unused_outer_edges, placings) do |_unused_outer_edges|
          if placings[pos1].sides[side1].matches(placings[pos2].sides[side2])
            solution = solve(placings, level + 1, _unused_outer_edges)
            return solution if solution
          end
        end
      end
      placings[unfilled_pos] = nil
      false
    end
  end

end

if ARGV[0] == "webgen"
  Solver.new.run(webgen: true)
else
  Solver.new.run
end
