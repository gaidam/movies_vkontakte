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
# print.rb
#
# This file contains function print_index  for printing index of movies out
#

require 'erb' 

$templates = {}

def get_template(name, type)
	ext = 'r' + type.to_s
	dir = ext
	filepath = dir + '/' + name + '.' + ext
	unless $templates.has_key? filepath		
		$templates[filepath] = File.exist?(filepath) ? File.read(filepath) : nil			
	end
	$templates[filepath]
end

def print_with_template(out, name, type, binding=TOPLEVEL_BINDING)
	template = get_template name, type
	unless template.nil?
		erb = ERB.new(template)
		out.puts erb.result(binding)
	end
end

def print_index(out, index, type)	
	print_key_attrs = !index.sub_index? 
	print_with_template out, 'pre', type
	print_index_level out, index, type, 0, Movie::ATTRIBUTES.clone, print_key_attrs do 
		yield if block_given?
	end
	print_with_template out, 'post', type
end

def print_index_level(out, index, type, level, attrs, print_key_attrs)  
  attr = index.index_key  
  attrs.delete(attr) unless print_key_attrs
  index.each do |key, movies|
  	yield if block_given?
    title = Movie.attr_to_s(attr, key)
    print_with_template(out, index.sub_index? ? 'key' : 'list', type, binding)
    print_index_level(out, movies, type, level + 1, attrs, print_key_attrs) if index.sub_index?
  end
end


