#
# movies_vkontakte
#
# This software is Public Domain
# 
# This program creates indices for collection of cult movies 
# vkontakte (http://vkontakte.ru/club2698666)
#
# Author
#    Dmitry Gaidamovitch, gaidam@mail.ru
#
# You must be registered vkontakte user to use this program.
#
# movies.rb
#
# Entry point for console ruby application
#

require "rubygems"
require "highline/import"
require 'net/http'
require 'cgi'
require 'pp' 

require 'movie' 
require 'myhttp' 
require 'vkontakte' 
require 'print' 

def parse_command_line_formats
	formats = ARGV.find_all { |arg| 
		arg =~ /(-f|--format)=.*/ }.map { |str| 
			str.split('=')[1].intern }
	
	print_usage('Wrong format!!!') unless formats.find { |format| 
		![:txt, :html].include?(format) }.nil?
	
	formats = formats.inject({}) { |h, str| h[str] = true; h }.keys
	formats = [ :html ] if formats.empty?	
	formats
end


def parse_command_line_attributes
	attrs = ARGV.find_all { |arg| 
		arg =~ /(-a|--attrs)=.*/ }.map { |str| str.split('=')[1] }
			
	print_usage('There can be only one attribute list!!!') if attrs.length > 1
	
	if attrs.empty?
		[ :director, :year ] 
	else
		attrs = attrs[0].split(',').map { |a| a.intern }
		print_usage('Wrong attribute!!!') unless attrs.find { |attr| 
			!Movie::ATTRIBUTES.include?(attr) }.nil?
		attrs
	end
end


def print_usage(msg=nil)
	puts msg unless msg.nil?
	puts %{
This program creates indices for collection of cult movies 
vkontakte (http://vkontakte.ru/club2698666)
        
Command line options are:

--format             (-f)
    Set resuling movie index file format (optional)
       txt  - plain text
       html - html with hyperlinks (by default)
      
       
--attrs              (-a)    
	Set list of attributes, for example:
	   -a=director,year  - this will build index first arranged by directors' names, 
	                       then by year in groups of movies with the same author
	                       (space after comma is not allowed)
	                       
       -attrs=name       - this will build alphabetical list of movies
       
       Supported attributes:
          name, director, year, duration    	          

--help               (-h)
	Show this message
}
exit
end


def input(prompt, echo = true)
	p = ask(prompt.to_s.capitalize + ': ') { |q| q.echo = echo }
	p == '' ? input(prompt, echo) : p
end


def login
  puts 'Please login to vkontakte.ru'
  {
  	'email' => input(:email), 
  	'pass' => input(:password, false)
  }
end


def collect_movies(site, club, attrs)
  index = Movie::Index.new(attrs)   
  club.each_video_page(site) do |path|  
    yield
    Club.each_video_link(site, path) do |title, path, video_index|        
      attrs = Club.parse_video_as_movie title
      unless attrs.nil?
		attrs[:path_vkontakte] = path
	    index.add Movie.new(attrs)
	  end
    end
  end
  index
end


def create_movie_indices(formats, attrs)
	vkontakte(login) do |site|
	  club = Club.new(2698666)
	  puts 'Collecting movies info'
	  index = collect_movies(site, club, attrs) { putc '.' }
	  formats.each do |format|
	  	puts
	  	puts 'Generating index in ' + format.to_s + ' format'
	  	file_name = 'movie_index.' + format.to_s
	  	File.open(file_name, 'w+')	do |out|  
	  		print_index(out, index, format) { putc '.' }
  		end
	  end
	end
end
	
print_usage unless ARGV.find { |arg| ['-h', '--help'].include? arg }.nil?
formats = parse_command_line_formats
attrs = parse_command_line_attributes
create_movie_indices formats, attrs
