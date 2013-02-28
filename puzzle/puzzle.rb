#!/usr/bin/ruby -w
# coding: UTF-8

# source location : https://github.com/mqu/divers/tree/master/puzzle

require 'pp'
# require 'backports' # gem install backports  / array:rotate / ruby 1.8

def memory_usage 
	`ps -o rss= -p #{Process.pid}`.to_i # in kilobytes 
end

class PuzzleException < Exception
end

class SolverException < PuzzleException
end

class PuzzleSpecsSingleton
	attr_accessor :specs

	def initialize
		# voir schema-match.png
		# cette table permet de réaliser les matchs depuis une position
		# sur le puzzle.
		# connaissant la position (0..9), on sait quelles sont les pièces voisines
		# et les cotés à vérifier.
		# par exemple : la case 0 est voision de 1 et 3
		# la vérification portera sur 0 (face0) <-> 1 (face2)
		# ce qui se traduit par "0:0" <-> "1:2" donc ['0:0', '1:2']
		#
		@specs = {
			0 => [['0:0', '1:2'], ['0:1', '3:3']],
			1 => [['1:2', '0:0'], ['1:0', '2:2'], ['1:1', '4:3']],
			2 => [['2:2', '1:0'], ['2:1', '5:3']],
			3 => [['3:3', '0:1'], ['3:0', '4:2'], ['3:1', '6:3']],
			4 => [['4:3', '1:1'], ['4:2', '3:0'], ['4:0', '5:2'], ['4:1', '7:3']],
			5 => [['5:3', '2:1'], ['5:2', '4:0'], ['5:1', '8:3']],
			6 => [['6:3', '3:1'], ['6:0', '7:2']],
			7 => [['7:2', '6:0'], ['7:3', '4:1'], ['7:0', '8:2']],
			8 => [['8:2', '7:0'], ['8:3', '5:1']]
		}
		@specs = self.optimize @specs
	end

	# éviter les opérations complexes sur la structure @specs (split)
	def optimize specs
		specs2 = {}
		specs.each { |k,p|
			recs = []
			p.each { |rec|
				x = rec[0].split(':')
				y = rec[1].split(':')
				recs << [x[0].to_i, x[1].to_i, y[0].to_i, y[1].to_i]
			}
			specs2[k] = recs
		}

		return specs2
	end

end

SPECS = PuzzleSpecsSingleton.new

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
		@specs = SPECS.specs
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

	def put idx, p
		raise "index error" if idx<0 || idx>8
		@cases[idx] = p
	end

	def [] idx
		raise "index error" if idx<0 || idx > 8
		@cases[idx]
	end

	def reset
		# une case vide est marquée par nil
		@cases = [
			nil, nil, nil, 
			nil, nil, nil, 
			nil, nil, nil]
	end

	# est-ce que la pièce posée sur la case 'pos' est OK ?
	def match? pos
		bool = true
		@specs[pos].each{ |t|
			bool = bool && self.matchx(t[0], t[2], t[1], t[3])
		}
		return bool
	end

	# retourne un tableau avec la liste des valeurs imposées par les pièces voisines
	# - nil pour les cases vides,
	# - ou la valeur
	# l'ordre des cases est celui-ci :
	#    3
	#  2 x 0
	#    1
	
	def constraints pos

		list = [nil, nil, nil, nil]
		@specs[pos].each { |c|
			# puts "# constraints :" ; pp c
			# pp @cases[c[2]]
			if @cases[c[2]]!=nil
				list[c[1]] = self.opposite(@cases[c[2]][c[3]])
			end
		}
		
		return list

	end
	
	# vérifie si 2 pièces "match" (coincident)
	# - p1, p2 : sont les index des pièces sur @cases
	# - x1, x2 : sont les faces des pièces à matcher.
	def matchx (p1, p2, x1, x2)

		# une case vide match toujours !
		return true if @cases[p1] == nil
		return true if @cases[p2] == nil

		p1 = @cases[p1]
		p2 = @cases[p2]
		a = p1[x1]
		b = p2[x2]

		return (a / 2 == b / 2 && a % 2 != b % 2)
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

	# 0 -> 1, 1 -> 0
	# 2 -> 3, 3 -> 2
	# ...
	def opposite n
		if n%2 == 0
			return n+1
		else
			return n-1
		end
	end

	def to_s
	
		return self.to_ascii

		s=sprintf("Puzzle: [%s]\n", self.id)
		@cases.each_with_index { |p,i|
			if p!= nil
				s << p.to_s
			else
				s << " - #{i+1} : vide\n"
			end
		}
	end

	def to_ascii
		s=sprintf("Puzzle (ascii) : [%s]\n", self.id)

		# table de transcodage
		# on converti les valeurs des animaux en A, B, C, D (tetes) et a, b, c, d pour le bas
		tr = ['A', 'a', 'B', 'b', 'C', 'c', 'D', 'd' ]

		out = Array.new(9) {Array.new(9)}
		out.each_with_index { |l,i|
			l.each_with_index { |c,j|
				out[i][j] = '.'
			}
		}
		out.map {|l| l.map {|c| c='.'}}
		(0..2).each{ |l|
			i=l*3

			f=3
			out[i+0][1]   = (@cases[i]!=nil)?tr[@cases[i][f]]:'x'
			out[i+0][1+3] = (@cases[i+1]!=nil)?tr[@cases[i+1][f]]:'x'
			out[i+0][1+6] = (@cases[i+2]!=nil)?tr[@cases[i+2][f]]:'x'

			f=2
			out[i+1][0]   = (@cases[i]!=nil)?tr[@cases[i][f]]:'x'
			out[i+1][0+3] = (@cases[i+1]!=nil)?tr[@cases[i+1][f]]:'x'
			out[i+1][0+6] = (@cases[i+2]!=nil)?tr[@cases[i+2][f]]:'x'

			f=0
			out[i+1][2+0] = (@cases[i]!=nil)?tr[@cases[i][f]]:'x'
			out[i+1][2+3] = (@cases[i+1]!=nil)?tr[@cases[i+1][f]]:'x'
			out[i+1][2+6] = (@cases[i+2]!=nil)?tr[@cases[i+2][f]]:'x'

			f=1
			out[i+2][1+0] = (@cases[i]!=nil)?tr[@cases[i][f]]:'x'
			out[i+2][1+3] = (@cases[i+1]!=nil)?tr[@cases[i+1][f]]:'x'
			out[i+2][1+6] = (@cases[i+2]!=nil)?tr[@cases[i+2][f]]:'x'
		}

		
		# print table
		out.map {|l| s << l.join(' ') + "\n"}

		return s
	end
	
	# sorte d'identifiant unique pour un puzzle résolu (ou pas?)
	def id
		l=[]
		
		# id des pièces
		@cases.each { |p|
			if  p==nil
				l<<'.'
			else
				l<< p.id
			end
		}
		
		# suivi de l'angle de rotation
		@cases.each { |p|
			if  p==nil
				l<<'.'
			else
				l << p.r
			end
		}
		
		# la liste est jointe et retournée sous forme de chaine.
		return l.join
	end
end

class Piece
	attr_reader :id

	def initialize id, v
		@values = v
		@id = id
		@rotate = 0
	end
	
	def to_s
		return sprintf(" - %d : [%s] / %d\n", @id, @values.rotate(@rotate%4).join(', '), @rotate%4)
	end

	def rotate count=1, r=:forward
		case r
			when :forward
				@rotate += count
			when :backward
				@rotate -= count

		end
	end
	
	def has? n
		return @values.include? n
	end
	
	# permet de faire tourner une pièce pour que la face i porte la valeur v
	def rotate_to v, i=0
		i=i%4
		while self.values[i] != v
			self.rotate
		end
		self
	end
	
	# tient compte de la rotation.
	def [] i
		raise "error : index to big #{i} for this Piece " + self.to_s if i >= @values.length
		raise "error : index to small #{i} for this Piece " + self.to_s if i < 0
		@values.rotate(@rotate%4)[i]
	end
	
	# tient compte de la rotation (voir self.[]) ; ce ne serait pas le cas de @values
	# la rotation affecte l'ordre des valeurs retournées.
	def values
		l = []
		(0..3).each { |i|
			l<<self[i]
		}
		return l
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
	
	# retourne la valeur de la rotation de la pièce
	def r
		@rotate%4
	end
end

class Solver

	def initialize
		@puzzle = Puzzle.new
		@tas = Tas.new
	end
	
	# not really a solver yet.
	def solve

	end

	def print
		# pp @tas
		puts @puzzle
	end

	def solved?
		return @puzzle.solved?
	end
end

# un solveur aléatoire : ne parviendra jamais à résoudre le problème, sauf avec bcp de chance.
class RandomSolver < Solver

	def solve
		(0..8).each {
			 p = @tas.take(:random)
			 p.rotate(rand(0..3))
			 @puzzle << p
		}
		return @puzzle
	end
end

# solveur avec une partie aléatoire couplée à une stratégie de remplissage
# - le solveur qui commence par la case du millieu
# - et essaie de trouver des pièces sur les 4 cotés (1, 3, 5, 7)
# - puis les coins.
class PseudoRandomSolver < Solver
	def solve
		# 0 1 2
		# 3 4 5
		# 6 7 8

		# on tire une pièce au hazard dans le tas
		p = @tas.take(:random)
		
		# elle est tournée aléatoirement.
		p.rotate(rand(0..3))
		
		# puis la pièce est posée sur dans le puzzle, à la position 4 (centre)
		@puzzle.put(4, p)

		begin
			[1, 3, 5, 7].each { |i|
				c = @puzzle.constraints(i)
				l =  @tas.find_with_constraints(c)
				# arrive assez rarement : apres avoir placé qq pièces, on a pas de soluce à ce niveau
				if l.length==0
					raise "ne peut résoudre ce puzzle ..." 
				end
				# prendre une pièce au hasard dans la liste
				p = l.sample
				# la retirer du tas
				@tas.take(p)
				
				#printf("contrainte : [%s]\n", c.join(', '))
				#printf("list : [%s]\n", l.join(', '))
				#printf "pièce sélectionnée : " ; puts p

				# faire tourner la pièce selon les contraintes.
				# la première occurrence non nulle dans la liste c permet de faire tourner la pièce
				c.each_with_index{ |v, j|
					if v != nil
						p.rotate_to(v,j)
						break
					end
				}
				# l'inserer dans le puzzle 
				@puzzle.put(i, p)

			}

		
			# terminer par les coins.
			[0, 2, 6, 8].each { |i|
				c = @puzzle.constraints(i)
				l =  @tas.find_with_constraints(c)
				
				if(l.length > 0)
					# prendre une pièce au hasard dans la liste
					p = l.sample

					# la retirer du tas
					@tas.take(p)
					
					# l'inserer dans le puzzle
					@puzzle.put(i, p)

					# faire tourner la pièce selon les contraintes.
					# la première occurrence non nulle dans la liste c permet de faire tourner la pièce
					c.each_with_index{ |v, j|
						if v != nil
							p.rotate_to(v,j)
							break
						end
					}

					# on vérifie que la pièce déposée match bien.
					if not @puzzle.match? i
						raise "erreur : la pièce posée ne coincide pas !"
					end
				else
					# pas de solution trouvée dans le tas ; on abandonne la boucle.
					break
				end
			}
		rescue => e
			# puts "## erreur : pas de solution"
			# p e
			# pp e.backtrace
		end


		if(@tas.size == 0)
			if @puzzle.solved?
				# puts "## 1 : puzzle résolu : "
				return @puzzle
			else
				# ne devrait pas arriver.
				# puts "### 2 : error : puzzle complet mais pas résolu"
				# puts @puzzle
				# puts @tas
				return false
			end
		else
			# puts "### 3 : non résolu ..."
			return false
		end
	end
end

# le tas est là ou sont placées les pièces avant d'être déposées sur la grille (puzzle).
# c'est dans le Tas que sont crées toutes les instances de Pièces (à l'initialisation).
class Tas

	# création du tas avec toutes les pièces.
	def initialize
		@pieces = []

		#                     distribution (non uniforme)
		# 0 coccinelle top    5
		# 1 coccinelle bottom 4
		# 2 sauterelle top    3
		# 3 sauterelle bottom 6 
		# 4 araignée top      5
		# 5 araignée bottom   4
		# 6 abeille top       6
		# 7 abeille bottom    3

		# inventaire selon image.
		self << Piece.new(1, [5, 6, 4, 3]) # 1
		self << Piece.new(2, [3, 1, 4, 6]) # 2
		self << Piece.new(3, [5, 0, 2, 6]) # 3
		self << Piece.new(4, [3, 0, 6, 7]) # 4
		self << Piece.new(5, [5, 7, 2, 0]) # 5
		self << Piece.new(6, [3, 6, 4, 1]) # 6
		self << Piece.new(7, [2, 4, 0, 1]) # 7
		self << Piece.new(8, [4, 0, 3, 6]) # 8
		self << Piece.new(9, [1, 3, 5, 7]) # 9

	end

	# ajouter un pièce dans le tas.
	def << p
		@pieces << p
	end

	# retourne le nombre de pièces disponibles dans le tas
	def size
		@pieces.length
	end

	# prendre une pièce dans le tas : 
	#  - aléatoire ou suivant son index
	#  - ou une pièce si idx_or_p est une pièce.
	def take(idx_or_p=0)
		raise "error : parametre ne peut pas être nil" if idx_or_p == nil
		if idx_or_p == :random
			p = @pieces.sample
		elsif idx_or_p.instance_of?(Piece)
			# prendre une pièce ; ne rien faire ici.
			p = idx_or_p
		else
			# FIXME : erreur aléatoire : puzzle.rb:403:in `[]': no implicit conversion from nil to integer (TypeError)
			p = @pieces[idx_or_p]
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
		ll = []
		self.find(l).each{ |p|
			found = false
			count=0
			while (not found) && (count<4)
				if p.values.join.include?(l.join)
					ll << p 
					found = true
				end
				p.rotate
				count +=1
			end
		}
		
		return ll
	end

	# retrouve dans le tas les pièces dont les contraintes 
	# sont énnoncées par c
	#
	# exemple : find_with_constraints(c=[1, nil, 4, nil])
	# - c doit être un tableau de 4 éléments représentant les 4 valeurs (faces) d'une pièce
	# - nil indique une non contrainte.
	#
	def find_with_constraints(c=[])
	
		# liste de retour. contiendra une liste de pièces dont les faces sont identiques à la contrainte "c"
		ll = []

		# on récupère la liste sans les nil c.delete_if{|e| e==nil}
		# et on fait une première sélection self.find sur cette liste
		cc = c.clone
		cc.delete_if{|e| e==nil}

		self.find(cc).each{ |p|
			found = false
			count=0
	
			# on essaie de faire matcher la liste, éventuellement en faisant tourne la pièce
			while (not found) && (count<4)
				# on clone la pièce pour éviter de modifier l'orinal qui sera retourné si match
				pp = p.values.clone
				# on remplace les nil sur la pièce clonée (pp) par les valeurs de c
				# ce qui permettra d'ignorer les nil lors de la comparaison ci-dessous
				(0..3).each { |i|
					pp[i] = nil if c[i] == nil
				}
				
				# les 2 pièces sont identiques, en ignorant les nil
				if pp=c
					# arretons de tourner en rond.
					found=true
					p.reset
					# ajout dans la liste des résultats
					ll << p
				end
				count +=1
				p.rotate
			end
		}
		return ll
	end
	
	def to_s
		s = sprintf("Tas (reste %d) : \n", @pieces.length)
		@pieces.each { |p|
			s = s + p.to_s
		}
		return s
	end
end

case ARGV[0]

when "puzzle"

	puzzle = Puzzle.new
	puzzle.reset
	puzzle.put 1, Piece.new(1, [4, 0, 1, 2])
	puzzle.put 3, Piece.new(3, [4, 0, 1, 2])

	puzzle << Piece.new(0, [1, 2, 3 , 4])
	puzzle << Piece.new(2, [2, 3 , 4, 1])

	pp puzzle

	puzzle.reset
	pp puzzle

when "puzzle:ascii"

	puzzle = Puzzle.new

	tas = Tas.new
	(1..8).each{
		puzzle << tas.take
	}

	puts puzzle

when "puzzle:match"

	puzzle = Puzzle.new
	puzzle.reset

	tas = Tas.new
	(1..9).each{
		puzzle << tas.take
	}

	pp puzzle
	(0..8).each{ |i|
		pp puzzle.match? i
	}

when "puzzle:constraints"

	puzzle = Puzzle.new
	puzzle.reset

	# 0 1 2
	# 3 4 5
	# 6 7 8
	# puzzle.put(0, Piece.new(1, [5, 6, 4, 3])) # 1
	# puzzle.put(1, Piece.new(2, [3, 1, 4, 6])) # 2
	# puzzle.put(2, Piece.new(3, [5, 0, 2, 6])) # 3
	# puzzle.put(3, Piece.new(4, [3, 0, 6, 7])) # 4
	puzzle.put(4, Piece.new(5, [5, 7, 2, 0])) # 5
	# puzzle.put(5, Piece.new(6, [3, 6, 4, 1])) # 6
	# puzzle.put(6, Piece.new(7, [2, 4, 0, 1])) # 7
	# puzzle.put(7, Piece.new(8, [4, 0, 3, 6])) # 8
	# puzzle.put(8, Piece.new(9, [1, 3, 5, 7])) # 9

	# à tester :
	#- 2 : [1, 4, 6, 3] / 1
	#- 5 : [7, 2, 0, 5] / 1
	#- 8 : [0, 3, 6, 4] / 1
	#- 3 : [0, 2, 6, 5] / 1
	#- 6 : [4, 1, 3, 6] / 2
	#- 1 : [6, 4, 3, 5] / 1
	#- 4 : [0, 6, 7, 3] / 1
	#- 7 : [4, 0, 1, 2] / 1
	#- 9 : [3, 5, 7, 1] / 1
 
 
	pp puzzle
	pp puzzle.constraints(1)

when "puzzle:optimize"

	puzzle = Puzzle.new
	puzzle.reset
	pp puzzle

when "puzzle:solved"

	puzzle = Puzzle.new
	puzzle.reset

	tas = Tas.new
	(1..9).each{
		puzzle << tas.take
	}

	puts "resolu" if puzzle.solved?
	puts puzzle

when "tas:take"
	tas = Tas.new
	pp tas
	# pp tas.take(0)
	# pp tas.take(:random)
	pp tas.take(Piece.new(4, [3, 0, 6, 7]))
	pp tas

when "tas:find"

	tas = Tas.new
	(0..7).each { |i|
		l = tas.find [i]
		puts "# find : #{i} ; #{l.length}"
		pp l
		puts "\n\n"
	}

when "tas:find_strict"

	tas = Tas.new

	# pp tas.find [0, 1, 2] # > [ 7 : [2, 4, 0, 1] / 0]
	# pp tas.find [7, 2, 0] # [ 5 : [5, 7, 2, 0] / 0]

	# pp tas.find_strict [7, 0, 2] #-> []
	# pp tas.find_strict [7, 2, 0] #-> [ 5 : [5, 7, 2, 0] / 0]
	pp tas.find_strict [2, 0, 5, 7] #-> [ 5 : [0, 5, 7, 2] / 3]
	pp tas.find_strict [2, 0, 7, 5] #->  []
	pp tas.find_strict [4, 0, 1, 2] #-> [ 7 : [2, 4, 0, 1] / 0]
	pp tas.find_strict [0, 1, 2, 4] #-> [ 7 : [0, 1, 2, 4] / 2]
	pp tas.find_strict [1, 2, 4, 0] #-> [ 7 : [1, 2, 4, 0] / 3]

when "tas:find_constraints"

	tas = Tas.new

	# pp tas.find_with_constraints [5, 0, 2, 6]
	l = tas.find_with_constraints [6, nil, nil, 2]
	pp tas
	pp l
	
	tas.take l[0]

	pp tas

when "tas:distribution"
	# affiche la distribution des pièces
	tas = Tas.new
	res = {}
	(0..7).each { |i|
		l = tas.find [i]
		res[i] = l.length
	}
	res.sort_by {|_key, value| value}.each { |k,v|
		puts " - #{k} : #{v}"
	}
	# - 7 : 3
	# - 2 : 3
	# - 1 : 4
	# - 5 : 4
	# - 4 : 5
	# - 0 : 5
	# - 6 : 6
	# - 3 : 6

when "piece:rotate"
	p = Piece.new(1, [4, 0, 1, 2])
	puts p
	p.rotate

	p = Piece.new(4, [1, 2, 3, 4])
	puts p
	p.rotate
	puts p

when "piece:rotate_to"
	p = Piece.new(1, [4, 0, 1, 2])
	puts p

	(0..3).each { |i|
		puts p.rotate_to(4,i)
	}

when "solver:random"

	(1..1000000).each {
		solver = RandomSolver.new
		puzzle = solver.solve   # rempli de facon aléatoire le puzzle
		if puzzle.solved?
			puts puzzle
		end
	}

when "solver:pseudo-random"

	puzzles = {}
	count = 0

	(1..1000000).each { |iter|
		# print '.'
		solver = PseudoRandomSolver.new
		puzzle = solver.solve 
		if(puzzle != false)
			id = puzzle.id
			
			# si la clé est dans la liste (ou pas)
			if puzzles.key? puzzle.id
				printf '.'
				puzzles[id][:count] += 1
				puzzles[id][:iters] << iter
			else
				printf '#'
				puzzles[id] = {
					:puzzle => puzzle,
					:count  => 1,
					:iters  => [iter]
				}
			end
		end
		count += 1
	}
	puts "\n"
	sum=0
	puzzles.each {|k,rec|
		sum += rec[:count]
	}
	printf("nombre de solutions trouvées : %d (dont doublons : %d)/ %d\n", puzzles.length, sum - puzzles.length, count)
	puzzles.each { |k, rec|
		puts rec[:puzzle]
		printf "- trouvé %d fois : \n", rec[:count]
		printf "- iterations (%s) \n", rec[:iters].join(", ")
		puts '-'*60
	}

end

