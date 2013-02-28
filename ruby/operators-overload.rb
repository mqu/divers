#!/usr/bin/ruby
# coding: UTF-8

require 'pp'



class List
	def initialize l
		@values = l
	end
	
	def [] i
		@values[i]
	end

	def []= i, v
		@values[i] = v
	end

end

l = List.new [1,2,3]
pp l
pp l[1]

l[1] = 123
pp l
