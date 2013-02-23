#!/usr/bin/ruby
# coding: UTF-8

require 'pp'

def memory_usage 
	memory_usage = `ps -o rss= -p #{Process.pid}`.to_i # in kilobytes 
end

class Puzzle

	def initialize
		@cases = []
	end
	
	def << p
		@cases << p
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
end

# le tas est là ou sont placées les pièces avant d'être déposées sur la grille (puzzle).
# c'est dans le Tas que sont crées toutes les instances de Pièces (à l'initialisation).
class Tas

	# création du tas avec toutes les pièces.
	def initialize
		@pieces = []
		self << Piece.new(1, [4, 0, 1, 2])
		self << Piece.new(2, [7, 2, 0, 5])
		self << Piece.new(3, [3, 5, 7, 1])
		self << Piece.new(4, [6, 4, 0, 3])
		self << Piece.new(5, [6, 4, 3, 5])
		self << Piece.new(6, [5, 0, 2, 6])
		self << Piece.new(7, [6, 3, 1, 4])
		self << Piece.new(8, [6, 7, 3, 0])
		self << Piece.new(9, [6, 4, 1, 3])
	end

	# ajouter un pièce dans le tas.
	def << p
		@pieces << p
	end

	# prendre une pièce dans le tas : aléatoire ou suivant son index
	def take(idx)
		if idx == :random
			p = @pieces.sample
		else
			p = @pieces[idx]
		end
		@pieces.delete(p)
	end
	
	# retrouve les pièces contenant les chiffres passés en parametres (l:array).
	def find(l=[])
		list = []
		@pieces.each { |p|
			list << p if p.contains l
		}
		return list
	end
end

tas = Tas.new
pp tas
puts ("---------")
# pp tas.take(0)
# pp tas.take(0)
# pp tas

# distribution non uniforme des pièces :
# find : 0 ; 5
# find : 1 ; 4
# find : 2 ; 3
# find : 3 ; 6
# find : 4 ; 5
# find : 5 ; 4
# find : 6 ; 6
# find : 7 ; 3
#(0..7).each { |i|
#	l = tas.find [i]
#	puts "# find : #{i} ; #{l.length}"
#	pp l
#	puts "\n\n"
#}
pp tas.find [0, 1, 2]
pp tas.find [7, 2, 0]

exit

solver = Solver.new(tas)

pp solver







