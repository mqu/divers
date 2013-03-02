# Recursive backtracking algorithm for maze generation. Requires that
# the entire maze be stored in memory, but is quite fast, easy to
# learn and implement, and (with a few tweaks) gives fairly good mazes.
# Can also be customized in a variety of ways.
# source : https://gist.github.com/jamis/754545

DIRS     = (N, S, E, W = 1, 2, 4, 8)
DX       = { E => 1, W => -1, N =>  0, S => 0 }
DY       = { E => 0, W =>  0, N => -1, S => 1 }
OPPOSITE = { E => W, W =>  E, N =>  S, S => N }

width  = (ARGV[0] || 10).to_i
height = (ARGV[1] || width).to_i
seed   = (ARGV[2] || rand(0xFFFF_FFFF)).to_i

srand(seed)

cells = Array.new(height) { Array.new(width, 0) }
stack = [[0, 0, DIRS.sort_by{rand}]]

until stack.empty?
  x, y, directions = stack.last

  until directions.empty?
    direction = directions.pop
    nx, ny = x + DX[direction], y + DY[direction]

    if nx >= 0 && ny >= 0 && nx < width && ny < height && cells[ny][nx] == 0
      cells[y][x] |= direction
      cells[ny][nx] |= OPPOSITE[direction]
      stack.push((x, y, directions = [nx, ny, DIRS.sort_by{rand}]))
    end
  end

  stack.pop
end

puts " " + "_" * (width * 2 - 1)
height.times do |y|
  print "|"
  width.times do |x|
    print((cells[y][x] & S != 0) ? " " : "_")
    if cells[y][x] & E != 0
      print(((cells[y][x] | cells[y][x+1]) & S != 0) ? " " : "_")
    else
      print "|"
    end
  end
  puts
end

puts "#{$0} #{width} #{height} #{seed}"

=begin

sample example.

# ruby maze.rb 35 15
 _____________________________________________________________________
|_______  |  _    |_    |_____   ___   ___|    ___  | |  _   _______  |
| |     | |___| |_  | | |  _  |_  |  _|  ___| |_   _|  _|  _| |  _____|
| | | |_| |  ___| | | |___|___  |_| |  _____|_  | | |_  |_  |___  |   |
|  _|_  |___|   |  _|  _____  |_  |___  |  _____| |_  |_  |___  | |_| |
| |    ___|  _|___|  _______| | |_  |_  | | |   |_  |  _| |  ___| |   |
| | |_|   |_  |_____|   |  ___|  _|_  | | |___| |  _|  ___| | |  _| |_|
| |_____|_  |_________| | |   |_  |  _| | |   | |_  |___|  _| | |___  |
|_   _|    _____  | |  _| | |  ___| |  _|___| |___________|  _| |   | |
|  _|  _| |  _  |  _| |  _| |_|  ___| |   |  _|  _  |___    |  _| | | |
| |  _|_  | | | |_|  _|_  |  ___|   | | |___|  ___| |    _|_|_  | |___|
| |___  | | | | |  _|  ___| |  ___| | | |  ___|   | | | |  _  | |___  |
| | |  _|_|_  |___|_   _  |___|  ___| |_____|  _|___| |_|_  |___|   | |
| | |___    |_  |   |___| |  _|___  | |  _____|  _  |_  |  _|    _|_  |
|_  | |  _|___| | |_  |  _|   |   | |_| |  ___  |_______| |___| |  _| |
|_____|___________|_____|___|___|_______|_____|_________________|_____|

=end
