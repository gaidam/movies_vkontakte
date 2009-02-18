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
# myhttp.rb
#
# Simple HTTP client functions
#

# If you want to use proxy, you can set it here like this:
#  $proxy_addr = '172.16.0.78'
#  $proxy_port = 3128

# No proxy
$proxy_addr = nil
$proxy_port = nil
  

def translate_cookies_from(str)
  cookies = CGI::Cookie.parse(str) 
  ['path', 'domain', 'expires'].each { |value| cookies.delete value  }
  str = ''  
  cookies.each { |name, cookie|   str += name + '=' + cookie.value[0] + '; ' }  
  str
end

def with_cookie(host, path, params)
  Net::HTTP::Proxy($proxy_addr, $proxy_port).start(host) { |http|    
    str_params = params.to_a.collect { |p| p[0] + '=' + p[1]}.join('&')
    response = http.post(path, str_params)
    connection = { 
      :http => http, 
      :params => { 'Cookie' => translate_cookies_from(response['set-cookie']) } 
    }
    yield connection   
  }
end

def get_page(conn, path)    
  resp, data = conn[:http].get(path, conn[:params])
  if resp.message == 'OK'
    yield data
  else
    trace_response('ERROR GETTING PAGE', resp)
  end 
end

def trace_header(key, val)
  puts 'Header = ' + key
  pp val 
  puts
end

def trace_response(title, response)
  puts
  puts '----------------------'
  puts title
  puts '----------------------'
  puts
  puts "Code = #{response.code}"
  puts "Message = #{response.message}"
  response.each {|key, val| trace_header(key, val)  }
end

