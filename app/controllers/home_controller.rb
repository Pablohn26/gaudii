#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

class HomeController < ApplicationController
  def index
    session[:design] = Design.new
    @design= find_design
    
    ip = request.remote_ip.to_s
    ip.gsub!('.','')
    t = Time.now
    local_time = t.strftime("%Y%m%d%H%M%S")
    @design.visitor_id = local_time+'_'+ip
  end

  def about
    render :partial => "about"
  end
  
  def source
    render :partial => "source"
  end

  def find_design
    unless session[:design]
      session[:design] = Design.new
    end
    session[:design]
  end

end
