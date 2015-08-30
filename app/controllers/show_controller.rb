#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

require 'fie.rb'
require 'compositor.rb'

class ShowController < ApplicationController
  
  def find_design
    unless session[:design]
      session[:design] = Design.new
    end
    session[:design]
  end
  
  def find_genetic_array
    unless session[:genes]
      session[:genes] = Array.new
    end
    session[:genes]
  end
  
  def find_designs_paths
    unless session[:paths]
      session[:paths] = Array.new
    end
    session[:paths]
  end
  
  def find_designs_array
    session[:designs_array]
  end
  
  def show_big_design
    @path= params[:url].to_s
    
    render :partial => "big_design"
  end

  #In case the generation did not 
  #generate a design 
  def show_fail
    render :partial => "fail"
  end
  
  def show_xml
    @item_number= params[:item_n]
    
    render :partial => "xml"
  end
  
  def get_xml
    @item_number = params[:item_n].to_i
    @designs_array = find_designs_array
    
    @current_design = @designs_array[@item_number]
        
    @url= @current_design.get_xml
    
    #It gives the file to the browser for
    #downloading it
    send_file @url
  end
  
  def upload_xml
    base = "public/uploaded_xml/"
    DataFile.save(params[:upload], base)
    
    upload = params[:upload]
    path = "public/uploaded_xml/"+upload['datafile'].original_filename
    
    @design = find_design
    design_clone = @design.deep_clone
    begin
      create_design_from_xml(design_clone, path)
    rescue
      flash[:notice] = I18n.t('flash.wrong_xml')
      redirect_to(:action => 'designs')
    end
  end
  
  def create_design_from_xml(design_clone, path)
    doc = Document.new(File.new(path))
    session[:paths] = Array.new
    @designs_paths = find_designs_paths
    session[:designs_array] = Array.new
    @designs_array = find_designs_array
    root = doc.root
    colors = []
    bg_colors = []
    primary_font = ''
    secondary_font = ''
    gen_bits = Genes.new
    
    root.elements.each do |e|
      if e.name == "genes"
        genes_string = e.attributes["string"]
        genes_string.each_char do |char|
          gen_bits << char.to_i
        end
      elsif e.name == "background" or e.name == "foreground"
        e.elements.each do |c|
          if e.name == "foreground"
            colors << Colour.new(c.attributes["red"].to_i, c.attributes["green"].to_i,c.attributes["blue"].to_i)
          else
            bg_colors << Colour.new(c.attributes["red"].to_i, c.attributes["green"].to_i,c.attributes["blue"].to_i)
          end
        end
      elsif e.name == "fonts"
        e.elements.each do |f|
          if f.attributes["type"] == "primary"
            primary_font = f.attributes["font"]
          else
            secondary_font = f.attributes["font"]
          end
        end
      end
    end
    
    fuzzy_engine = Fie.new
    
    #There are three designs:
    #1) Same genetic array, same colors, same fonts
    #2) Same genetic array, same colors
    #3) Same genetic array, same fonts
    
    design_clone.gen_bits = gen_bits.deep_clone
    design_colors = design_clone.deep_clone
    design_fonts = design_clone.deep_clone
    
    design_clone.current_number = 10
    design_colors.current_number = 11
    design_fonts. current_number = 12
    
    fuzzy_engine.run_fie(design_clone)
    fuzzy_engine.run_fie(design_colors)
    fuzzy_engine.run_fie(design_fonts)

    design_clone.colors = colors.deep_clone
    design_clone.background = colors[0].deep_clone
    design_clone.bg_colors = bg_colors.empty? ? [] : bg_colors.deep_clone
    design_colors.colors = colors.deep_clone
    design_colors.background = colors[0].deep_clone
    design_colors.bg_colors = bg_colors.empty? ? [] : bg_colors.deep_clone
    
    design_clone.primary_font = primary_font
    design_clone.secondary_font = secondary_font
    design_fonts.primary_font = primary_font
    design_fonts.secondary_font = secondary_font
    
    design_clone.generate_design_values(true, true)
    design_colors.generate_design_values(true, false)
    design_fonts.generate_design_values(false, true)
    
    @designs_paths << Compositor.new.create_png(design_clone)
    @designs_paths << Compositor.new.create_png(design_colors)
    @designs_paths << Compositor.new.create_png(design_fonts)
    @designs_array << design_clone
    @designs_array << design_colors
    @designs_array << design_fonts
    
    redirect_to(:action => 'designs', :xml => 'true')
    
  end
  
  #Drop_zone is the mixer, where the user
  #drop the designs
  def update_drop_zone
    @genes = find_genetic_array
    @designs_array = find_designs_array
    @already_in = false
        
    @genes << @designs_array[params[:id].to_i].gen_bits
    
    render :partial => "dropzone"
  end
  
  #The generator function
  def get_designs
    @design = find_design
    
    session[:designs_array] = Array.new
    
    #design_paths is an array where the paths
    #of the designs (normal size and thumbnail)
    #are stored. 
    @designs_paths = []
    
    n_designs = 9

    @design.current_number=0
    @designs_array = find_designs_array
    fuzzy_engine = Fie.new
    n_designs.times do |n|  
      @designs_array[n] = @design.deep_clone

      @design.current_number +=1
    end
    
    @designs_array.each do |d|
      #Genetic production
      d.gen_bits.start_creation(d.init_questions, d.image_shape)
      d.gen_bits.mod_entries_bits(d.main_image.width, d.main_image.height)
      
      #Fuzzy inference engine
      fuzzy_engine.run_fie(d)
      
      print '>> Nuevo diseño - ['+d.current_number.to_s+'] - '
      d.gen_bits.each do |c|
        print c
      end
      puts ''
      
      begin
        #Values generation
        d.generate_design_values
        #Composition
        @designs_paths << Compositor.new.create_png(d)
      rescue
        #If there is an exception, it shows an error
        #but the process continue for the rest of
        #designs.
        @designs_paths << ['fail', 'fail.png']
      end

    end

    @genes = @find_genetic_array

    render :partial => "designs_table"

  end
  
  #Mixer function
  def get_similar_designs
    @design = find_design
    session[:designs_array] = Array.new
    @designs_paths = []
    @genes = find_genetic_array
    
    n_designs = 9

    @design.current_number=0
    @designs_array = find_designs_array
    fuzzy_engine = Fie.new
    n_designs.times do |n|  
      @designs_array[n] = @design.deep_clone
      @design.current_number +=1
    end

    #Preparing the genetic childs and parents
    gen_family = []
    children = []
    gen_family[0] = @genes
    
    @genes.length.times do |n|
      @genes.length.times do |i|
        if n != i
          children << @genes[n].crossover(@genes[i])
        end
      end
    end
    
    gen_family[1] = children


    @designs_array.each do |d|
      #Genetic mix
      d.gen_bits = d.gen_bits.start_mix(d.init_questions, gen_family)
      d.gen_bits.mod_entries_bits(d.main_image.width, d.main_image.height)
      
      #Fuzzy inference engine
      fuzzy_engine.run_fie(d)
      print '>> Nuevo diseño - ['+d.current_number.to_s+'] - '
      d.gen_bits.each do |c|
        print c
      end
      puts ''

      begin
        #Values generation
        d.generate_design_values
        #Composition
        @designs_paths << Compositor.new.create_png(d)
      rescue
        @designs_paths << ['fail', 'fail.png']
      end
    end

    session[:genes] = Array.new
    @genes = find_genetic_array

    render :update do |page|
      page.replace_html 'show_designs', :partial => 'designs_table'
      page.replace_html 'drop_zone', :partial => 'dropzone'
    end

  end
  
  def designs
    @design = find_design
    
    if @design.init_questions.empty?
      redirect_to(:controller => :collect, :action => 'preferences')
    elsif @design.main_image == nil
      if @design.init_questions['q1'] == '2' #Flickr image
        redirect_to(:controller => :collect, action => :flickr_image)
      elsif @design.init_questions['q1'] == '1' #Upload image
        redirect_to(:controller => :collect, :action => :upload_image)
      end
    elsif @design.main_image.interest_box_x == nil
      redirect_to(:controller => :collect, :action => :interest_spot)
    elsif @design.groups.empty?
      redirect_to(:controller => :collect, :action => :text)
    end
    
    session[:genes] = Array.new
    @xml = params[:xml]=='true' ? true : false
    if @xml
      @designs_paths = find_designs_paths
    end    
  end

end
