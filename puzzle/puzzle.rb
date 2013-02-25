#!/usr/bin/ruby
# coding: UTF-8

# source location : https://github.com/mqu/divers/tree/master/puzzle

require 'pp'

def memory_usage 
	memory_usage = `ps -o rss= -p #{Process.pid}`.to_i # in kilobytes 
end

class Puzzle

	# Puzzle :
	#	- les cases : numérotées : 1..9 (0..8 pour le programme)
	#	- disposition :
	#		1 2 3 | 0 1 2 
	#		4 5 6 | 3 4 5
	#		7 8 9 | 6 7 8
	#
	# Piece :
	# - possède 4 valeurs disposées sur chaque face.
	# 	     3
	#	   2 P 0
	#		 1

	def initialize
		# voir schema-match.png
		@specs = {
			0 => [['0:0', '1:2'], ['0:1', '3:3']],
			1 => [['1:2', '0:0'], ['1:0', '2:2'], ['1:1', '4:3']],
			2 => [['2:2', '1:0'], ['2:1', '5:3']],
			3 => [['3:3', '0:1'], ['3:0', '4:2'], ['3:1', '6:3']],
			4 => [],
			5 => [],
			6 => [],
			7 => [],
			8 => []
		}
		self.reset
	end

	# insère la pièce "p" sur le puzzle sans gérer l'ordre.
	# l'insersion est réalisée dans la première cellule vide.
	def << p
		@cases.each_index { |i|
			if @cases[i] == nil
				@cases[i] = p
				return
			end
		}
	end

	def put p, idx
		raise "index error" if idx<0 || idx > 8
		@cases[idx] = p
	end

	def reset
		# une case vide est marquée par nil
		@cases = [
			nil, nil, nil, 
			nil, nil, nil, 
			nil, nil, nil]
	end

	def match? pos
		puts "# Puzzle:match(#{pos})\n"

		pp @specs[pos].each{ |x,y|
			puts "match? #{x}, #{y}\n"
		}
		exit

	end
	
	# vérifie si 2 pièces "match" (coincident)
	# - p1, p2 : sont les index des pièces sur @cases
	# - x1, x2 : sont les faces des pièces à matcher.
	def matchx (p1, p2, x1, x2)
		# une case vide match toujours !
		return true if @cases[p1] == nil
		return true if @cases[p2] == nil
		
	end

	# check if puzzle solved.
	def solved?
	
		# pour toutes les pièces
		(0..8).each { |i|
			# la case est encore vide : solved = false
			return false if @cases[i] == nil
			
			# sinon, est-ce que les pièces matchent entre elles.
			return false if not self.match?(i)
		}
		
		# sinon, ca match partout : le puzzle est résolu (solved) !
		return true
	end

end

class Piece
	def initialize id, v
		@values = v
		@id = id
		@rotate = 0
	end
	
	def to_s
		return sprintf(" %d : [%s] / %d", @id, @values.rotate(@rotate%4).join(', '), @rotate%4)
	end
	
	def rotate r, count=1
		case r
			when :left
				@rotate += count
			when :right
				@rotate -= count
		end
	end
	
	def has? n
		return @values.include? n
	end
	
	def rotate_to n
		raise "error : can't find value #{n} for this Piece " + self.to_s unless self.has? n
		self.rotate(:left, @values.index(n))
		self
	end
	
	def [] i
		raise "error : index to big #{i} for this Piece " + self.to_s if i >= @values.length
		raise "error : index to small #{i} for this Piece " + self.to_s if i < 0
		@values.rotate(@rotate%4)[i]
	end
	
	def reset
		@rotate = 0
		self
	end
	
	# check if Piece contains array 'l' of values.
	def contains l
		l.each { |e|
			return false if ! self.has? e
		}
		
		return true
		
	end
end

class Solver

	def initialize
		@puzzle = Puzzle.new
		@tas = Tas.new
	end
	
	# not really a solver yet.
	def solve
		m1 = memory_usage
		list = []
		(1..1000).each{ |c|
			p = Puzzle.new
			@pieces.each { |i| p << i}
			list << p
			puts c if c % 10000 == 1
		}
		
		m2 = memory_usage
		
		printf("memory : %d\n", (m2 - m1))
	end

	def print
		pp @tas
		pp @puzzle
	end

	def solved?
		return @puzzle.solved?
	end
end

# un solveur aléatoire : ne parviendra jamais à résoudre le problème, sauf avec bcp de chance.
class RandomSolver < Solver

	def solve
		(1..9).each {
			@puzzle << @tas.take(:random)
		}
	end
end

# le tas est là ou sont placées les pièces avant d'être déposées sur la grille (puzzle).
# c'est dans le Tas que sont crées toutes les instances de Pièces (à l'initialisation).
class Tas

	# création du tas avec toutes les pièces.
	def initialize
		@pieces = []

		# 0 coccinelle top
		# 1 coccinelle bottom
		# 2 sauterelle top
		# 3 sauterelle bottom
		# 4 araignée top
		# 5 araignée bottom
		# 6 abeille top
		# 7 abeille bottom

		# inventaire Pierre
		#self << Piece.new(1, [4, 0, 1, 2]) # 7
		#self << Piece.new(2, [7, 2, 0, 5]) # 5
		#self << Piece.new(3, [3, 5, 7, 1]) # 9
		#self << Piece.new(4, [6, 4, 0, 3]) # 8
		#self << Piece.new(5, [6, 4, 3, 5]) # 1
		#self << Piece.new(6, [5, 0, 2, 6]) # 3
		#self << Piece.new(7, [6, 3, 1, 4]) # 2
		#self << Piece.new(8, [6, 7, 3, 1]) # 4
		#self << Piece.new(9, [6, 4, 1, 3]) # 6

		# inventaire selon image.
		self << Piece.new(1, [2, 4, 0, 1])
		self << Piece.new(2, [5, 7, 2, 0])
		self << Piece.new(3, [1, 3, 5, 7])
		self << Piece.new(4, [3, 1, 6, 7])
		self << Piece.new(5, [5, 6, 4, 3])
		self << Piece.new(6, [5, 0, 2, 6])
		self << Piece.new(7, [3, 1, 4, 6])
		self << Piece.new(8, [4, 0, 3, 6])
		self << Piece.new(9, [3, 6, 4, 1])

	end

	# ajouter un pièce dans le tas.
	def << p
		@pieces << p
	end

	# prendre une pièce dans le tas : aléatoire ou suivant son index
	def take(idx=0)
		if idx == :random
			p = @pieces.sample
		else
			p = @pieces[idx]
		end
		
		# une pièce qui est prise est otée du tas.
		@pieces.delete(p)
	end
	
	# retrouve tous les pièces du tas contenant les id passés dans la liste l
	# - l : est une liste []
	def find(l=[])
		list = []
		@pieces.each { |p|
			list << p if p.contains l
		}
		return list
	end

	# retrouve toutes les pièces ayant les id, mais dans l'ordre.
	def find_strict(l=[])
		# FIXME : à terminer.
		self.find l
	end
end

case ARGV[0]

when "puzzle"

	puzzle = Puzzle.new
	puzzle.reset
	puzzle.put Piece.new(1, [4, 0, 1, 2]), 1
	puzzle.put Piece.new(3, [4, 0, 1, 2]), 3

	puzzle << Piece.new(0, [1, 2, 3 , 4])
	puzzle << Piece.new(2, [2, 3 , 4, 1])

	pp puzzle

	puzzle.reset
	pp puzzle

when "puzzle:match"

	puzzle = Puzzle.new
	puzzle.reset

	tas = Tas.new
	(1..9).each{
		puzzle << tas.take
	}

	puzzle.match? 0

when "tas:take"
	tas = Tas.new
	pp tas
	puts ("---------")
	pp tas.take(0)
	pp tas.take(:random)
	pp tas

when "tas:find"
	# distribution non uniforme des pièces :
	# find : 0 ; 5
	# find : 1 ; 4
	# find : 2 ; 3
	# find : 3 ; 6
	# find : 4 ; 5
	# find : 5 ; 4
	# find : 6 ; 6
	# find : 7 ; 3
	(0..7).each { |i|
		l = tas.find [i]
		puts "# find : #{i} ; #{l.length}"
		pp l
		puts "\n\n"
	}

	# pp tas.find [0, 1, 2]
	# pp tas.find [7, 2, 0]

when "solver"
	solver = Solver.new(tas)
	pp solver
	
when "random-solver"
	solver = RandomSolver.new
	solver.solve
	solver.print
	pp solver.solved?
end

