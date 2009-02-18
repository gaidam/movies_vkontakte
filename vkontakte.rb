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
# vkontakte.rb
#
# Class Club, function vkontakte
#

#
# Class Club: movies info extraction from pages containing video
#

class Club
  attr_reader :id  
  
  def initialize(id)
    @id = id
  end  
  
  def path_to_video
    "/video.php?gid=" + @id.to_s
  end
  
  def count_video_pages(conn)
    get_page(conn, path_to_video) do |content|
      m = content.match(/<div class=\"summary\"><b>(\d+)/)
      m.nil? ? nil : m[1].to_i/100+1
    end
  end 
  
  def each_video_page(conn, count = nil)
    count = count_video_pages(conn) if count.nil?
    if count.nil?
      puts 'Cannot recognize page count'
    else      
      0.upto(count-1) do |page|
        yield path_to_video + "&st=#{page * 100}"
      end
    end
  end
  
  def self.each_video_link(conn, path)
    get_page(conn, path) { |content|
      links = content.scan(/<a href=\"(video-.*?)\">(.*?)<\/a>/)      
      links.each_with_index { |link, index| 
        path = link[0]
        title = link[1]
        yield title, path, index
      }      
    }    
  end
    
  # This implementation is specific for club2698666.
  # So if you want to parse movies from other groups 
  # you'll have to change it with new requirements
  def self.parse_video_as_movie(str)
  
    attrs = {}
    
    # Movie title formatting rules:      
    
    # 1) Title ::= Director(s) - Other information 
    match = str.match(/(.*?)\s+-\s+(.*)/)
    return nil if match.nil?
    
    attrs[:director] = parse_director(match[1])
    str = match[2]  
    
    # 2) Other information ::= Name (yyyy) duration мин.
    
    # (yyyy)
    match = str.match(/.*?\((\d\d\d\d)\).*/)
    unless match.nil?
      attrs[:year] = match[1].to_i
      p1, p2 = match.begin(1)-1, match.end(1)+1   
      str = str[0, p1] + str[p2, str.length-p2]
    end
    
    # duration мин.
    match = str.match(/.*?(\d+)\s*мин\.*.*/)
    unless match.nil?
      attrs[:duration] = match[1].to_i
      str = str[0, match.begin(1)]
    end
    
    # Name
    attrs[:name] = str.strip
    
    attrs  
  end
  
  # Director string:
  #   - name fisrt, family name second;
  #   - there can be the comma separated list of directors;
  #   - last two directors can be connected with "и"
  #   - family names can be presented with two words (f.e.: ван Ванмердам)
  #   - there can be hyphens in both names and family names
    
  def self.parse_director(str)
  	ary = str.split(/\s*,\s*|\s+и\s+/).map { |item| exchange_names(item) }.compact
  end
  
  def self.exchange_names(str)
  	pos = str.index /\s+/
  	return nil if pos.nil?  	
  	str[pos, str.length - pos].strip + ' ' + str[0, pos]
  end  
  
end

# Session vkontakte
def vkontakte(login_params)
  with_cookie('vkontakte.ru', '/login.php', login_params)  { |conn|  yield conn }
end


