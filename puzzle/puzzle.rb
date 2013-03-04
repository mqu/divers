#!/usr/bin/ruby -w
# coding: UTF-8

=begin

author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

source location : https://github.com/mqu/divers/tree/master/puzzle

links : 

backtracking :
- http://www.hbmeyer.de/backtrack/backtren.htm

matching edge puzzles :
- http://en.wikipedia.org/wiki/Edge-matching_puzzle

Eternity II puzzle :
- http://www.eternity-puzzle.com/
- http://www.cse.iitk.ac.in/users/cs365/2012/submissions/anirkus/cs365/projects/report.pdf
 - http://home.iitk.ac.in/~anirkus/cs365/projects/slides.pdf
- http://grokcode.com/10/e2-the-np-complete-kids-game-with-the-2-million-prize/
- http://eternity2blogger.over-blog.com/pages/Editor_and_Solver_for_Eternity_II-1767319.html

en francais :
- http://drgoulu.com/2008/01/13/eternity-ii/
- http://royale.zerezo.com/eternity2/

=end

require 'pp'
# require 'backports' # gem install backports  / array:rotate / ruby 1.8

def memory_usage 
	`ps -o rss= -p #{Process.pid}`.to_i # in kilobytes 
end

class PuzzleException < Exception
end

class SolverException < PuzzleException
end

# cette classe permet de déclarer les interdépedances entre toutes les pièces lorsqu'elles
# sont placées dans une case du puzzle.
# - les dépendances sont déclarées sous formes de couples (pi=piece, fi=face ) (p1:f1) - (p2:f2)
# - la déclaration est réalisée sous forme de chaine de caractère facilitant la lisibilité,
# - afin d'optimiser le fonctionnement, la méthode optimize() permet de transformer
#   le couple en tableau : [p1, f1, p2, f2]
# - une seule instance est nécessaire pour le fonctionnement du logiciel ; c'est donc une classe singleton.
#
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

	# optimisation de la structure specs
	# éviter la répétion des opérations complexes (split et to_i en particulier)
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

# création d'une instance de la classe Singleton.
SPECS = PuzzleSpecsSingleton.new

# le puzzle est une classe de type container dans laquelle :
# - on insère des pièces
# - on vérifie que les pièces coincident entre elles,
# - on vérifie sur le problème est résolu (solved?)
# - c'est le puzzle qui donnera pour un emplacement donné, la liste des
#   contraintes pour poser une pièces sous forme de liste : c=[v0, v1, v2, v3]
#   - les valeurs v[0..3] représentent les faces des pièces à poser,
#   - une valeur nil indique aucune contrainte sur la pièce à poser,
#   - une valeur numérique indique la valeur imposée
#   - l'ordre de la liste est important, mais la rotation de la liste permet
#     de matcher plusieurs combinaisons.
#
class Puzzle

	attr_reader  :tr

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

		# table de transcodage
		# on converti les valeurs des animaux en A, B, C, D (têtes) et a, b, c, d pour le bas
		@tr = ['A', 'a', 'B', 'b', 'C', 'c', 'D', 'd' ]

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
	# - nil indique une non-contrainte
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
	
	def constraints_to_s l
		_l=l.clone
		l.each_with_index do |v,i|
			_l[i] = @tr[v] if v != nil
		end
		return _l
	end
	# vérifie si 2 pièces "match" (coincident)
	# - p1, p2 : sont les index des pièces sur @cases
	# - f1, f2 : sont les faces des pièces à matcher.
	def matchx (p1, p2, f1, f2)

		# une case vide match toujours !
		return true if @cases[p1] == nil
		return true if @cases[p2] == nil

		p1 = @cases[p1]
		p2 = @cases[p2]
		a = p1[f1]
		b = p2[f2]

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
	
		# return self.to_ascii
		s = self.to_ascii 

		s << sprintf("Puzzle: [%s]\n", self.id)
		@cases.each_with_index { |p,i|
			if p!= nil
				s << sprintf(" - [%d] /%s", i, p.to_s)
			else
				s << sprintf(" - [%d] / - vide\n", i)
			end
		}
		return s
	end

	def face_tr idx, f

		return 'x' if @cases[idx] == nil
		return @tr[@cases[idx][f]]
	end

	def to_ascii
		s=sprintf("Puzzle : [%s]\n", self.id)

		out = Array.new(9) {Array.new(9)}
		out.each_with_index { |l,i|
			l.each_with_index { |c,j|
				out[i][j] = '.'
			}
		}

		(0..2).each do |i|

			f=0 ; (0..2).each { |j| out[i*3+1][j*3+2] = self.face_tr(i*3+j, f) }
			f=1 ; (0..2).each { |j| out[i*3+2][j*3+1] = self.face_tr(i*3+j, f) }
			f=2 ; (0..2).each { |j| out[i*3+1][j*3+0] = self.face_tr(i*3+j, f) }
			f=3 ; (0..2).each { |j| out[i*3+0][j*3+1] = self.face_tr(i*3+j, f) }

		end
		
		# print table
		out.map {|l| s << l.join(' ') + "\n"}

		return s
	end

	
	# identifiant unique pour un puzzle résolu (ou pas?)
	# constitué de la concaténation des n° de pièce + rotation.
	# permet d'identifier de manière unique un puzzle.
	#
	def id
		l=[]
		
		# id des pièces
		@cases.each do |p|
			if  p==nil
				l<<'.'
			else
				l<< p.id
			end
		end
		
		# suivi de l'angle de rotation
		@cases.each do |p|
			if  p==nil
				l<<'.'
			else
				l << p.r
			end
		end
		
		# la liste est jointe et retournée sous forme de chaine.
		return l.join
	end
end

# la pièce :
# - est potentiellement unique (dans ce jeu, c'est le cas)
# - possède 
#   - un id (numéro de rang) ; facilite la lisibilité pour le débugage,
#   - 4 valeurs numériques,
#   - un angle de rotation
# - les méthodes :
#   - rotation
#   - has? : permet de savoir si la pièce contient une valeur
#   - contains? (l) : permet de vérifier si la pièce contient la liste l
#   - rotate_to : permet de faire tourner la pièce selon une contrainte déterminée (valeur, index)
#
# relations avec les autres classes :
#  - Tas : 
#    - ajouter : <<
#    - prendre (take) selon index ou aléatoire
#    - rechercher : find, find_strict, find_with_constraints
#  - Puzzle
#    - ajouter : <<, put
#    - validation, vérification : match*
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
		return self if count==0
		case r
			when :forward
				@rotate += count
			when :backward
				@rotate -= count
		end
		return self
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
	def contains? l
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

# classe de base  pour le solveur : déclatation de l'interface
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

# un solveur aléatoire : ne parviendra jamais à résoudre le problème, sauf avec bcp de chance (itérrations)
# l'intéret est surtout de montrer l'API et l'agencement des différentes méthodes.
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

# résolveur parcourant un arbre complet avec toutes les possibilités.
# FIXME : à terminer ...
class BrutForceSolver < Solver

	def initialize
		@puzzle = Puzzle.new
		@tas = TasOrdonne.new  # pour ce type de solveur, nous avons besoin d'un tas qui gère les index
		# @tas.suffle  # on mélange les pièces.
	end

	def solve
		printf("# BruteForceSolver:solve\n")
		
		# on doit avoir un tas ordonné
		raise "error" unless @tas.is_a? TasOrdonne

		solutions = []

		begin

			(0..8).each { |p|
				tas = @tas.clone
				puzzle = @puzzle.clone
				self.each_p tas, puzzle, p
			}

		rescue PuzzleException => e
			# solutions << puzzle
			puts "exeption"
			pp e
			raise
		end
	end

	# p est l'index de la pièce à piocher dans le tas 
	# r = nb rotation
	def each_p tas, puzzle, _p
		printf("# BruteForceSolver:each_p p=%d\n", _p)
		
		p = tas.take(_p)
		puzzle << p

		if tas.size > 0
			_tas = @tas.clone
			_puzzle = @puzzle.clone
			self.each_p _tas, _puzzle, _p+1
		else
			# est-ce que le puzzle est valide
			if puzzle.solved?
				printf("## 1 : puzzle résolu\n")
				puts puzzle
			end
		end

	end
end

# solveur avec une partie aléatoire couplée à une stratégie de remplissage
# - le solveur qui commence par la case du millieu
# - et essaie de trouver des pièces sur les 4 cotés (1, 3, 5, 7)
# - puis les coins.
class PseudoRandomSolver < Solver
	def solve

		# emplacement des cases dans le puzzle
		# 0 1 2
		# 3 4 5
		# 6 7 8

		begin
		
			# on commence par la position centrale du puzzle
			l = [4]
			# on commence par les 4 cotés de la pièce centrale
			[1, 3, 5, 7].shuffle.each { |i| l << i} 

			# puis on termine par les 4 coins
			[0, 2, 6, 8].shuffle.each { |i| l << i} 
	
			l.each do |i|
			
				res = self.inserer_position(i) 
				raise "erreur d'insertion" if res == :error
				
			end

		rescue PuzzleException => e
			puts "## erreur : pas de solution"
			# p e
			# pp e.backtrace
		end

		if(@tas.size == 0)
			if @puzzle.solved?
				# on a trouvé une solution acceptable ; on retourne la réponse.
				return @puzzle
			else
				# ne devrait pas arriver.
				return false
			end
		else
			# le tas n'est pas vide ; on est manifestement sur une impasse : combinaison impossible.
			# on retourne false, indiquant un échec du solveur.
			return false
		end
	end
	
	def inserer_position pos

		printf "## inserer_position %d\n", pos

		if pos == 4
			# on tire une pièce au hazard dans le tas
			p = @tas.take(:random)
			
			# elle est tournée aléatoirement.
			p.rotate(rand(0..3))
			
			# puis la pièce est posée sur dans le puzzle, à la position 4 (centre)
			@puzzle.put(pos, p)
			
			return true
		end

		c = @puzzle.constraints(pos)
		l =  @tas.find_with_constraints(c)
		
		# pas de pièce disponible avec les contraintes "c".
		return false if( l.size == 0)

		# prendre une pièce au hasard dans la liste
		p = l.sample

		# la retirer du tas
		@tas.take(p)
		
		# l'inserer dans le puzzle
		@puzzle.put(pos, p)

		# faire tourner la pièce selon les contraintes.
		# la première occurrence non nulle dans la liste c permet de faire tourner la pièce
		c.each_with_index do |v, j|
			if v != nil
				p.rotate_to(v,j)
				break
			end
		end

		# on vérifie que la pièce déposée match bien ; en principe cela ne devrait pas arriver !
		if not @puzzle.match? pos
			# raise PuzzleException.new "erreur : la pièce posée ne coincide pas !"
			printf "## match-error : %d\n", pos
			printf "contraintes : [%s] / [%s]\n", c.join(','), @puzzle.constraints_to_s(c).join(',')
			printf "liste : " ; pp l
			printf "pièce : " ; pp p
			printf "tas : "   ; pp @tas
			printf "puzzle : " ; pp @puzzle
			printf "tr table : [%s]\n", @puzzle.tr.join(',')
			return :error
		end
		
		# la pièce est posée et coincide.
		return true
		
	end

	def solve_sav
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
			[1, 3, 5, 7].shuffle.each do |i|
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

				# faire tourner la pièce selon les contraintes.
				# la première occurrence non nulle dans la liste c permet de faire tourner la pièce
				c.each_with_index do |v, j|
					if v != nil
						p.rotate_to(v,j)
						break
					end
				end
				# l'inserer dans le puzzle 
				@puzzle.put(i, p)

			end

		
			# terminer par les coins.
			[0, 2, 6, 8].shuffle.each do |i|
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
					c.each_with_index do |v, j|
						if v != nil
							p.rotate_to(v,j)
							break
						end
					end

					# on vérifie que la pièce déposée match bien.
					if not @puzzle.match? i
						raise "erreur : la pièce posée ne coincide pas !"
					end
				else
					# pas de solution trouvée dans le tas ; on abandonne la boucle.
					break
				end
			end
		rescue => e
			# puts "## erreur : pas de solution"
			# p e
			# pp e.backtrace
		end

		if(@tas.size == 0)
			if @puzzle.solved?
				# on a trouvé une solution acceptable ; on retourne la réponse.
				return @puzzle
			else
				# ne devrait pas arriver.
				return false
			end
		else
			# le tas n'est pas vide ; on est manifestement sur une impasse : combinaison impossible.
			# on retourne false, indiquant un échec du solveur.
			return false
		end
	end

end

# classe commune au Tas et TasOrdonne (pile?)
class TasCommun
	attr_reader :pieces

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

	def to_s
		s = sprintf("Tas (reste %d) : \n", self.size)
		@pieces.each { |p|
			s = s + p.to_s
		}
		return s
	end

	def suffle
		@pieces.shuffle!
	end
end


# le tas est là ou sont placées les pièces avant d'être déposées sur la grille (puzzle).
# c'est dans le Tas que sont crées toutes les instances de Pièces (à l'initialisation).
class Tas < TasCommun

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
			list << p if p.contains? l
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
end

# dans le Tas ordonné, les pièces peuvent être prise dans un ordre déterminé,
# le rang des pièces est conservé
# est utilisé pour le solveur de type force brute qui doit balayer tout un arbre
# 
class TasOrdonne < TasCommun
	def take(idx)
		if @pieces[idx]== nil
			return false
		else
			p = @pieces[idx]
			# on ne supprime pas la pièce ici, mais on la marque prise (nil)
			@pieces[idx] = nil
			return p
		end
	end
	
	def size
		l = @pieces.select { |p| p!=nil}
		return l.length
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
	(1..9).each{
		puzzle << tas.take
	}

	expected = <<-END
	Puzzle : [123456789000000000]
	. b . . D . . D .
	C . c C . b B . c
	. D . . a . . A .
	. d . . A . . a .
	D . b B . c C . b
	. A . . d . . D .
	. a . . D . . d .
	A . B b . C c . a
	. C . . A . . b .
	END
	expected.gsub!(/^\t/, '')
	result = puzzle.to_s

	if result  != expected
		puts "# not expected result !"
		puts "\n# result : "
		puts result
		puts "\n# having : "
		puts expected
	else
		puts "# OK ; it's expected result !"
		puts result
	end
	
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
	tas = Tas.new
	pieces = Tas.new.pieces.clone
	
	# 0 1 2
	# 3 4 5
	# 6 7 8

	# puzzle.put(0, Piece.new(1, [5, 6, 4, 3])) # 1
	# puzzle.put(1, Piece.new(2, [3, 1, 4, 6])) # 2
	# puzzle.put(2, Piece.new(3, [5, 0, 2, 6])) # 3
	# puzzle.put(3, Piece.new(4, [3, 0, 6, 7])) # 4
	# puzzle.put(4, Piece.new(5, [5, 7, 2, 0])) # 5
	# puzzle.put(5, Piece.new(6, [3, 6, 4, 1])) # 6
	# puzzle.put(6, Piece.new(7, [2, 4, 0, 1])) # 7
	# puzzle.put(7, Piece.new(8, [4, 0, 3, 6])) # 8
	# puzzle.put(8, Piece.new(9, [1, 3, 5, 7])) # 9

	#- [0] / - vide
	#- [1] / - 3 : [0, 2, 6, 5] / 1
	#- [2] / - vide
	#- [3] / - 8 : [0, 3, 6, 4] / 1
	#- [4] / - 6 : [6, 4, 1, 3] / 1
	#- [5] / - 5 : [0, 5, 7, 2] / 3
	#- [6] / - 7 : [2, 4, 0, 1] / 0
	#- [7] / - 9 : [7, 1, 3, 5] / 3
	#- [8] / - vide

	puzzle.put(1, pieces[3-1].rotate(1))
	puzzle.put(3, pieces[8-1].rotate(1))
	puzzle.put(4, pieces[6-1].rotate(1))
	puzzle.put(5, pieces[5-1].rotate(3))
	puzzle.put(6, pieces[7-1].rotate(0))
	puzzle.put(7, pieces[9-1].rotate(3))

	pp puzzle
	c = puzzle.constraints(6)
	pp c
	pp puzzle.constraints_to_s c

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

when "tas:ordonne"
	puzzle = Puzzle.new
	tas = TasOrdonne.new

	(0..8).each { |i|
		p = tas.take(i)
		puts p
		
		puzzle << p
	}

	puts puzzle
	puts tas
	puts tas.size

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

	tas = TasOrdonne.new

	# [0,1,2,3,4,5,6,7,8].each { |i| tas.take i}
	[1,2,4,5,6,7].each { |i| tas.take i}
	pp tas
	
	# pp tas.find_with_constraints [5, 0, 2, 6]
	l = tas.find_with_constraints [5,nil,nil,5]
	pp l


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

when "solver:brute-force"

	solver = BrutForceSolver.new
	solutions = solver.solve
	pp solutions


when "solver:pseudo-random"

	puzzles = {}
	count = 0

	(1..100000).each { |iter|
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
		# printf "- iterations (%s) \n", rec[:iters].join(", ")
		puts '-'*30
	}

end

