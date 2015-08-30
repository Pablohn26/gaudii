#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

class CollectController < ApplicationController
  attr_accessor :questions_array

  #find_design appears in every controllers. This finds
  #and return the cookie object (design).
  def find_design
    unless session[:design]
      session[:design] = Design.new
    end
    session[:design]
  end
  
  def find_provisional_group
    unless session[:group]
      session[:group] = Group.new
    end
    session[:group]
  end
  
  #Controller for the "preferences" view
  def preferences
    @questions_array = []
    doc = REXML::Document.new(File.new(I18n.t('step.two_questions')))
    root = doc.root
    root.elements.each do |e|
    	@questions_array << Question.new(e.attributes["number"], e.attributes["content"])
    	array_number = e.attributes["number"].to_i - 1
    	question_number=1
    	e.elements.each do |opt|
    		@questions_array[array_number].add_option(opt.attributes["content"], question_number)
    		question_number +=1
    	end
    end
    
    if params[:edit]=='yes'
      @prepare_for_changes = true
    else
      @prepare_for_changes = false
    end
    
  end
    
  #Cntroller for the "flickr_image" view
  def flickr_image
     @design = find_design
    if @design.init_questions.empty?
      redirect_to(:action => 'preferences')
    end
  end
    
  def edit_design
    @design = find_design
    
    if @design.main_image != nil
      array_path = @design.main_image.source.to_s.split('/')
      puts array_path[array_path.length-1]
      @path = array_path[array_path.length-1]
    end
    
    render :partial => "edit_design"
  end
  
  def edit_group
    @design = find_design
    @group_number=params[:id].to_i
    @group= @design.groups[params[:id].to_i]
    render :partial => "edit_group"
  end
    
  def alter_group
    @design= find_design
    @group = @design.groups[params[:group_number].to_i]
    
    @group.items.length.times do |n|
      @group.items[n].content = params['c'+n.to_s]
      @group.items[n].type = params['t'+n.to_s].to_i
    end
    
    redirect_to(:action => 'text')
  end  
  
  def remove_group
    @design= find_design
    @design.groups.delete_at(params[:group].to_i)
    redirect_to(:action => 'text')
  end  
  
  def add_main_elements
    @design= find_design
    
    g = Group.new()
    g.add_item(Letters.new(0, params[:c0]))
    if not params[:c1].empty?
      g.add_item(Letters.new(1, params[:c1]))
    end
    @design.add_group(g)
    redirect_to(:action => 'text')
  end
  
  #This attach an image to a 
  #text group
  def add_image_to_a_group
    base = "public/images/uploaded_pictures/"
    DataFile.save(params[:upload], base)
    
    upload = params[:upload]
    path = "public/images/uploaded_pictures/"+upload['datafile'].original_filename
    
    @design = find_design
    group_number = params[:group].to_i
    
    #The name will be like the main image
    #but adding a "_g#", where "#" is the
    #number of the group 
    new_name = @design.visitor_id.to_s+'_g'+group_number.to_s
    
    old_name = File.basename(path)
    old_name_array = old_name.split('.')
    new_name+='.'+old_name_array[1]
    
    File.rename(path, 'public/images/uploaded_pictures/'+new_name)
    
    if check_image_filetype('.'+old_name_array[1])
      @design.groups[group_number].has_image = true
      @design.groups[group_number].text_image = DesignImage.new('public/images/uploaded_pictures/'+new_name, 1)

      redirect_to(:action => 'text')
    else
      flash[:notice] = I18n.t('flash.wrong_image')
      
      redirect_to(:action => 'text')
    end    
    
  end
  
  #In the text view, this add a text group
  #to the design object
  def add_group
    @design = find_design
    g = Group.new()
    number_of_elements = (params.length-3)/2
    number_of_blank_fields = 0 
    number_of_elements.times do |n|
      content = params['c'+n.to_s]
      if not content.strip.empty?
        type = params['t'+n.to_s].to_i
        i = Letters.new(type, content)
        g.add_item(i)
      else
        number_of_blank_fields +=1
      end
    end
    
    if number_of_blank_fields==number_of_elements
      flash[:notice] = I18n.t('flash.all_blanks')
    else
      if number_of_blank_fields>0
        flash[:notice] = I18n.t('flash.blank')
      end
      @design.add_group(g)
    end
    redirect_to(:action => 'text')
  end

  #The Ajax call for adding or removing
  #text fields
  def modify_group_size
    @group = find_provisional_group
    
    if params[:n].to_i == 1
      @group.add_item(Letters.new())
    else
      if @group.items.length>1
        @group.items.delete_at(@group.items.length-1)
      end
    end
    
    render :partial => "text_fields"
  end
  
  def change_to
    if params[:adding_item]=='text'
      @group = find_provisional_group
      render :partial => 'adding_item_text'
    else
      @design=find_design
      @groups = @design.groups
      render :partial => 'adding_item_image'
    end
  end
  
  #This is the controller for the
  #"text" view
  def text
    @design=find_design
    
    if @design.init_questions.empty?
      redirect_to(:action => 'preferences')
    elsif @design.main_image == nil
      if @design.init_questions['q1'] == '2' #Flickr image
        redirect_to(:action => :flickr_image)
      elsif @design.init_questions['q1'] == '1' #Upload image
        redirect_to(:action => :upload_image)
      end
    elsif @design.main_image.interest_box_x == nil
      redirect_to(:action => :interest_spot)
    end
    
    session[:group] = Group.new
    @group= find_provisional_group
    
    n=3
    
    n.times do 
      @group.add_item(Letters.new())
    end
    
    #Groups array for editing
    @g_array = @design.groups 
    
  end  

  #Ajax search in Flickr
  def search
    #the API key    
    flickr = Flickr.new 'b715a2a59427bb1bbc91683af31877f5'
    
    begin
      render :partial => "photo", :collection => flickr.photos(:tags => params[:tags], 
      :license => params[:commercial_use], :per_page => '8', :sort => "interestingness-desc")
    rescue
      render :partial => "no_photo"
    end
  end
  
  def show_big_photo
    @path= params[:path].to_s
    @scale = ((600.0/params[:width].to_f)*100).to_i
    render :partial => "big_photo"
  end
  
  def interest_spot
    @design = find_design
    
    if @design.init_questions.empty?
      redirect_to(:action => 'preferences')
    elsif @design.main_image == nil
      if @design.init_questions['q1'] == '2' #Flickr image
        redirect_to(:action => :flickr_image)
      elsif @design.init_questions['q1'] == '1' #Upload image
        redirect_to(:action => :upload_image)
      end
    end
    
    @design.obtain_main_image_colors
    
    #We check wheter or not there has been
    #a interest spot found    
    if @design.main_image.analysis != nil
      @cv=true
      @path= @design.visitor_id+'_tmp.png'
      
    else
      @cv = false
      redirect_to(:action => 'interest_spot_manual')
      array_path = @design.main_image.source.to_s.split('/')
      puts array_path[array_path.length-1]
      @path = array_path[array_path.length-1]
    end

  end

  def interest_spot_manual
    @design = find_design
    
    if @design.init_questions.empty?
      redirect_to(:action => 'preferences')
    elsif @design.main_image == nil
      if @design.init_questions['q1'] == '2' #Flickr image
        redirect_to(:action => :flickr_image)
      elsif @design.init_questions['q1'] == '1' #Upload image
        redirect_to(:action => :upload_image)
      end
    end
    
    @design.obtain_main_image_colors

    array_path = @design.main_image.source.to_s.split('/')
    puts array_path[array_path.length-1]
    @path = array_path[array_path.length-1]

  end

  def add_spot
    @design=find_design
    
    #First it adds the image_shape
    if params[:image_shape].to_i==0
      @design.image_shape = 'curved'
    elsif params[:image_shape].to_i==1
      @design.image_shape = 'slightly curved'
    elsif params[:image_shape].to_i==2
      @design.image_shape = 'slightly straight'
    elsif params[:image_shape].to_i==3
      @design.image_shape = 'straight'
    end
    
    #Now it checks the interest spot depending on if it has been
    #manual or created by the computer vision modules.
    if params[:x1].to_i == 0 and params[:x2].to_i == 0 and params[:y1].to_i == 0 and params[:y2].to_i == 0 
      if params[:cv] == 'true'
        metrics = @design.main_image.analysis.split(' ')
        
        @x = metrics[0].to_i
        @y = metrics[1].to_i
        @width = metrics[2].to_i
        @height = metrics[3].to_i

        @design.main_image.add_interest_spot(@x, @y, @width, @height)
        redirect_to(:action => 'text')
      else
        flash[:notice] = I18n.t("flash.no_spot")
        redirect_to(:action => 'interest_spot_manual')
      end
    else
      @original_width= @design.main_image.width
      @original_height= @design.main_image.height
      @factor= @original_width.to_f / 600.0
      
      #We first create the spot
      @x = ((params[:x1].to_i)*@factor).to_i
      @y = ((params[:y1].to_i)*@factor).to_i
      @width = ((params[:x2].to_i - params[:x1].to_i)*@factor).to_i
      @height = ((params[:y2].to_i - params[:y1].to_i)*@factor).to_i
      
      #Checking the interest spot is not too big
      if (@width*@height).to_f/(@original_width*@original_height).to_f< 0.01 || (@width*@height).to_f/(@original_width*@original_height).to_f> 0.25
        flash[:notice] = I18n.t("flash.bad_spot")
        redirect_to(:action => 'interest_spot_manual')
      else
        @design.main_image.add_interest_spot(@x, @y, @width, @height)
        redirect_to(:action => 'text')
      end

    end
    
  end
  
  #A checking method for the image types.
  def check_image_filetype(ext)
    if (ext == '.jpeg' or ext == '.jpg' or ext == '.png' or ext == '.gif')
      return true
    else
      return false
    end
  end
  
  def upload_image_action
    @design = find_design
    base = "public/images/uploaded_pictures/"
    view_path = "uploaded_pictures/"
    DataFile.save(params[:upload], base)
    
    upload = params[:upload]
    path = "public/images/uploaded_pictures/"+upload['datafile'].original_filename
    
    aux_array = path.split('.')
    ext = '.'+aux_array.last.to_s
    
    if check_image_filetype(ext)
      new_path = base+@design.visitor_id+''+ext
      view_path += @design.visitor_id+''+ext
      File.rename(path, new_path)
      @design.add_main_image(new_path)

      redirect_to(:action => 'upload_image', :url => view_path)
    else
      flash[:notice] = I18n.t('flash.wrong_image')
      redirect_to(:action => 'upload_image')
    end
    
  end
  
  def upload_image
    @design = find_design
    
    if @design.init_questions.empty?
      redirect_to(:action => 'preferences')
    end
    
    @pic_url = nil
    if params[:url]!=nil
      flash[:notice] = I18n.t('flash.uploaded')
      @pic_url = params[:url]
    end
        
  end
  
  def download_flickr_image
    @design= find_design
    url = params[:url]
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    original_filename=File.basename(uri.path)
    puts File.basename(uri.path)
    aux_array = original_filename.split('.')
    ext = aux_array.last.to_s.length == 3? '.'+aux_array.last.to_s : ''
    full_url = 'public/images/uploaded_pictures/'+@design.visitor_id+''+ext
    http.start {
      http.request_get(uri.path) {|res| 
        File.open(full_url,'wb') { |f|
          f.write(res.body)
        }
      }
    }
    
    @design.add_main_image(full_url.to_s)
    redirect_to(:action => 'interest_spot')
  end
  
  
  def check_tastes_answers    
    @design= find_design
    @design.add_init_questions('q1', params[:q1])
    @design.add_init_questions('q2', params[:q2])
    @design.add_init_questions('q3', params[:q3])
    @design.add_init_questions('q4', params[:q4])
    @design.add_init_questions('q5', params[:q5])
    @design.add_init_questions('q6', params[:q6])
    
    if params[:changes] == 'true' and params[:q1] != @design.init_questions['q1']
      if params[:q1] == '1'
        @design.add_init_questions('q1', params[:q1])
        redirect_to(:action => :upload_image)
      elsif params[:q1] == '2'
        @design.add_init_questions('q1', params[:q1])
        redirect_to(:action => :flickr_image)
      end  
    else
      @design.add_init_questions('q1', params[:q1])
      
      if params[:q1].to_i==2 #Flickr image
        redirect_to(:action => :flickr_image)
      elsif params[:q1].to_i==1 #Upload image
        redirect_to(:action => :upload_image)
      end
    end

  end

  private

end
