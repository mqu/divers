#!/usr/bin/ruby
# coding: utf-8

# author : Marc Quinton, march 2013, licence : http://fr.wikipedia.org/wiki/WTFPL
# 
# some tests with mechanize library for ruby.
# 
# http://mechanize.rubyforge.org/

require 'pp'

require 'rubygems'
require 'mechanize'

def google
	a = Mechanize.new { |agent|
	  agent.user_agent_alias = 'Mac Safari'
	}

	a.get('http://google.com/') do |page|
	  search_result = page.form_with(:name => 'f') do |search|
		search.q = 'Hello world'
	  end.submit

	  search_result.links.each do |link|
		puts link.text
	  end
	end
end

=begin
account[login]	"login"
account[password]	your-password
account[remember_me]	0
account[remember_me]	1
commit	Se connecter
utf8	✓
=end


class LinuxFr 

	def initialize
		@a = Mechanize.new
	end

	def login login, password
		@a.get('http://linuxfr.org/') do |page|
			login = page.form_with(:action => '/compte/connexion') do |f|

				f['account[login]']     = login
				f['account[password]']  = password
				f['account[remember_me]']  = true
			end.submit
			
			@logout = login.form_with(:action => '/compte/deconnexion')
			return true if @logout != nil
			return false
		end
	end
	
	def logout
		if @logout != nil
			p = @logout.submit
			pp p
		end
	end
end

class AnnuCom 

	def initialize
		@a = Mechanize.new
	end

	def search query
		@a.get('http://annu.com') do |page|
			search = page.forms[0]
			search['q'] = query
			response = search.submit
			pp response

		end
	end
end


case ARGV[0]

	when "linuxfr"
		linuxfr = LinuxFr.new
		linuxfr.login ARGV[1], ARGV[2]
		linuxfr.logout
		
	when "annu"
		annu = AnnuCom.new
		annu.search ARGV[1]

	else
		printf("try with some options ; don't know for thoses one : (%s)\n" . ARGV.join(' '))
end
