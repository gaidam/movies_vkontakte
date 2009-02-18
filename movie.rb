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
# movie.rb
#
# Classes: Movie, Movie::Index
#


#
# Class Movie: movie attributes, movie url, to_s, each_attr
#
class Movie
  
  ATTRIBUTES =  [:name, :director, :year, :duration, :path_vkontakte]
  
  attr_reader :attrs
  
  def initialize(attrs)
    @attrs = attrs
  end
  
  def url
    to_s :path_vkontakte
  end
  
  def to_s(attr)
    unless attr.kind_of? Array
      Movie.attr_to_s(attr, @attrs[attr])
    else
      attrs = attr.clone
      str = ''
      Movie.each_attr do |attr|
        if attrs.include? attr      
          str += to_s(attr) + ' '
          attrs.delete attr
        end
      end
      attrs.each { |attr| str += to_s(attr) + ' ' }
      str      
    end
  end
  
  def self.attr_to_s(attr, value)
    if ([:year, :duration].include?(attr)) and (value.nil? or value < 0)
    	str = 'Unknown ' + ((attr == :year) ? 'year' : 'duration')
    elsif attr == :director    	
    	str = value.kind_of?(Array) ? value.join(', ') : value.to_s
    else
    	str = ''
    	str += 'http://vkontakte.ru/' if attr == :path_vkontakte
    	str += value.to_s
    	str += ' min.' if attr == :duration 
    end
    str
  end
  
  def self.each_attr
    ATTRIBUTES.each { |attr| yield attr }
  end
  
#
# Class Movie::Index: nested movie index
#

  class Index  
    
    attr_reader :keys
    
    def initialize(keys)
      @keys = keys
      @sub_keys = keys.clone
      @sub_keys.shift
      @hash = {}
    end
    
    def sub_index?
      @sub_keys.length > 0
    end
    
    # There can be multiple directors
    def add(movie)
    	keys = (index_key == :director) ? movie.attrs[:director] : [ movie.attrs[index_key] ]
    	keys.each do |key|
    		key = not_nil key
		    if sub_index?
		    	@hash[key] = Movie::Index.new(@sub_keys) unless @hash.has_key? key
		        @hash[key].add movie
		    else
		    	@hash[key] = [] unless @hash.has_key? key
		        @hash[key] << movie
		    end
    	end      
    end
    
    def index_key
      @keys[0]
    end    
    
    def not_nil(key)
      if key.nil? 
        if [:year, :duration].include?(index_key)
          key = -1 
        else
          key = 'Unknown ' + index_key.to_s
        end
      end
      key
    end
    
    def cmp_keys(a, b)
      reverse = [:year, :duration].include?(index_key) ? true : false
      if reverse
        return -1 if a.nil?
        return 1 if b.nil?
        return b <=> a
      else
        return 1 if a.nil?
        return -1 if b.nil?
        return a <=> b 
      end       
    end
    
    def each
      sorted_ary = @hash.sort { |a, b|  cmp_keys(a[0], b[0])  }
      sorted_ary.each { |item| yield item[0], item[1]  }
    end
    
  end 
  
end


