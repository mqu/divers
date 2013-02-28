
require 'pp'
# require 'singleton'

# usefull link : http://dalibornasevic.com/posts/9-ruby-singleton-pattern-again

class Point
	attr_accessor :x,:y

	def initialize x, y
		@x=x
		@y=y
	end

	def to_s
		"Point(#{@x},#{@y})"
	end
end

class Origin
	# attr_accessor :count
	private_class_method :new

	# uniq instance : Point(0,0)
	@@instance = Point.new(0, 0)
	
	# instance can't be changed.
	@@instance.freeze

	# count number of instances.
	@@count = 0


	def self.instance
		@@count+=1
		puts "# Origin:self.instance : count=#{@@count}\n"
		return @@instance
	end

	def stats
		puts "# Origin:stats : count=#{@@count}\n"
	end
end

o1 = Origin.instance
o2 = Origin.instance
# o3 = Origine.new # error  private method `new' called for Origine:Class (NoMethodError)


# o2.x = 123 # object if frozen

puts o1  # > Point(123,0)
puts o2  # > Point(123,0)

# puts "same object (instance)" if o1.__id__ = o2.object_id

# print Origin singleton class statistics
# pp Origin.count # don't know howto ...

