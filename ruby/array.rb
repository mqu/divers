# Program to find the factorial of a number
# Save this as fact.rb

require 'pp'

# adding pick_at and first! methods to array
#
class Array

	# pick an element at index
	def pick_at i
		v = self[i]
		self.delete_at i
		return v
	end
	
	# return the first element from array, removing it
	# != from Array:first because it removes element from list
	def first!
		self.shift
	end
end


a=[1,2,3,4,5,6]
a=%w[1 2 3 4 5 6]
a=Array (1..6)
a=(1..6).to_a

p a

p a.pick_at 1 # get second element from array
p f=a.first!  # f is removed from array
p s=a.first   # s not removed from array
pp a

