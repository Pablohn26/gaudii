#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

require 'rexml/document'
include REXML

class Design
  attr_accessor :groups, :width, :height, :vertical, :background, :gen_bits, :values_bits, :ratio, :image_colors
  attr_accessor :primary_font, :secondary_font, :image_shape, :predominant_shape, :colors, :bg_colors
  attr_accessor :sides_img_margin, :sides_margin, :upper_img_margin, :upper_margin
  attr_accessor :white_space_w, :white_space_h, :white_space_x, :white_space_y, :init_questions, :main_image 
  attr_accessor :interest_point, :interest_box, :visitor_id, :current_number, :max_width
  
  def initialize()
    @image_shape='curved'
    @groups = Array.new
    @values_bits = []
    @gen_bits = Genes.new
    @colors = []
    @bg_colors = []
    @image_colors = []  
    @init_questions = {}
    @current_number = 0
    @interest_point = []
  end
  
  def add_group(group)
    @groups << group
  end
  
  def add_init_questions(symbol, value)
    @init_questions[symbol] = value
  end
  
  def add_main_image(image_path)
    @main_image = DesignImage.new(image_path,Constants::Main_image)
    
    face_analysis = `./app/models/openCV/face/face #{@main_image.source}`
    blob_analysis = `./app/models/openCV/blob/blob #{@main_image.source}`
    
    face_array = face_analysis.split(' ')
    blob_array = blob_analysis.split(' ')

    if (face_array[2].to_i !=0 and face_array[3].to_i!=0) or (blob_array[2].to_i !=0 and blob_array[3].to_i!=0)
      if face_array[2].to_i !=0 and face_array[3].to_i!=0
         @main_image.analysis = face_analysis
      else
        @main_image.analysis = blob_analysis
      end
    
      metrics = @main_image.analysis.split(' ')
    
      picture = Image.read(@main_image.source).first
      gc = Draw.new
      gc.stroke('black')
      gc.stroke_width(3)
      gc.fill('none')
      gc.rectangle(metrics[0].to_i, metrics[1].to_i, metrics[0].to_i+metrics[2].to_i,metrics[1].to_i+metrics[3].to_i)
    
      gc2 = Draw.new
      gc2.stroke('white')
      gc2.stroke_width(1)
      gc2.fill('none')
      gc2.rectangle(metrics[0].to_i, metrics[1].to_i, metrics[0].to_i+metrics[2].to_i,metrics[1].to_i+metrics[3].to_i)
    
      gc.draw(picture)
      gc2.draw(picture)
      picture.write('public/images/uploaded_pictures/'+@visitor_id+'_tmp.png')
    else
      @main_image.analysis = nil
    end
    
  end
  
  def mod_gen_bits
    gen_bits.mod_entries_bits(@main_image.width, @main_image.height)
  end
  
  #This is the main function of the class
  #here is where all the functions are called
  def generate_design_values(xml_colors=false, xml_fonts=false)
    #DOCUMENT
    generate_ratio #Generates the ratio of the document
    generate_orientation #Generates if the design has horizontal or vertical orientation
    generate_sizes #Generates the sizes based on the ratio
    generate_margin
    if values_bits[Constants::V_Zooming]>4.5 and values_bits[Constants::V_Type_of_BG] > 4.5 #Plain BG and zooming activated
      modify_image
    end
    generate_images_sizes #Adjust the sizes based on the design sizes 
    generate_predominant_shape #Straight, curved, etc.

    #COLORS
    if not xml_colors
      generate_color_scheme
    end  
    if values_bits[Constants::V_Type_of_BG]>4.5
      improve_legibility 
    end
    if values_bits[Constants::V_Texts_BG]>3.5 and not xml_colors
      generate_text_backgrounds
    end

    #FONTS
    if not xml_fonts
      generate_family_fonts
    end
    
    groups.each do |g| #Groups
      g.items.each do |i| #Items
        if i.instance_of? Letters
          generate_font(i) 
        end
      end
    end

    #####PRECOMPOSITION
    composite_main_image_position
    generate_white_spaces   
    adapt_font_size
    initialize_composition_values
    if values_bits[Constants::V_Type_of_BG] > 4.5#Plain bg
      adapt_design_size
    end
    calculate_interest_point

    #Composition starts here
    start_composition
  end
  
  def adapt_font_size
    #Title and subtitle
    prev_size = @groups[0].items[0].font_size
    @groups[0].items[0].font_size = Letters.new.adjust_font_size(@groups[0].items[0], @white_space_w) #We check the length for the title
    shrink_ratio = prev_size.to_f / @groups[0].items[0].font_size.to_f
    
    if @groups[0].items.length>1
      @groups[0].items[1].font_size= (@groups[0].items[1].font_size/shrink_ratio).to_i
      
      @groups[0].items[1].font_size = Letters.new.adjust_font_size(@groups[0].items[1], @white_space_w)
    end
    
    least = Array.new
    least[2] = Constants::Big_num
    least[3] = Constants::Big_num
    least[4] = Constants::Big_num
    
    #Other elements
    (1..@groups.length-1).to_a.each do |n|
      if n!=0
        @groups[n.to_i].items.each do |item|
          item.font_size = Letters.new.adjust_font_size(item, @max_width)
          least[item.type] = item.font_size < least[item.type] ? item.font_size : least[item.type] 
        end
      end
    end
    
    #Adapting the sizes of the font to the least of every type
    (1..@groups.length-1).to_a.each do |n|
      if n!=0
        @groups[n.to_i].items.each do |item|
          item.font_size = least[item.type] 
        end
      end
    end
    
    
  end
  
  def generate_margin
    if values_bits[Constants::V_Type_of_BG] > 4.5 #Plain bg
      if values_bits[Constants::V_Margins]<1.5 #no sides_img_margin
        @sides_img_margin=0
        @upper_img_margin=0
        @sides_margin=20
        @upper_margin=20
      elsif values_bits[Constants::V_Margins]>=1.5 and values_bits[Constants::V_Margins]<4.5 #low
        @sides_img_margin=20
        @upper_img_margin=20
        @sides_margin=20
        @upper_margin=20
      elsif values_bits[Constants::V_Margins]>=4.5 and values_bits[Constants::V_Margins]<8 #medium
        @sides_img_margin=40
        @upper_img_margin=20
        @sides_margin=40
        @upper_margin=20
      else #high
        @sides_img_margin=40
        @upper_img_margin=40
        @sides_margin=40
        @upper_margin=20
      end
      
      if not @vertical
        @sides_margin= 20
      end   
      
    else #Picture as background
      @sides_img_margin=0
      @upper_img_margin=0
      @sides_margin=20
      @upper_margin=20
    end
  end

  #Zooming to the image
  def modify_image
    if @vertical
      @main_image = @main_image.zooming_v
    else
      @main_image = @main_image.zooming_h
    end
  end
  
  def generate_images_sizes
    previous_width = @main_image.width
    if values_bits[Constants::V_Type_of_BG] > 4.5 #Plain background
      if @width>@height || (@width==@height && @main_image.height > @main_image.width)
        img_ratio= @main_image.height.to_f/(@height - upper_img_margin*2).to_f
        @main_image.height = @height - upper_img_margin*2
        @main_image.width = @main_image.width.to_f / img_ratio
      elsif @width<@height || (@width==@height && @main_image.width > @main_image.height)
        img_ratio= @main_image.width.to_f/(@width - sides_img_margin*2).to_f
        @main_image.width = @width - sides_img_margin*2
        @main_image.height = @main_image.height.to_f / img_ratio
      elsif @width==@height and @main_image.width == @main_image.height
        modify_image
        generate_images_sizes
      end
    else
      @main_image.height = @height
      @main_image.width = @width
    end
    
    @main_image.readapt_interest_box(@width.to_f/previous_width.to_f)
  end
  
  def generate_sizes
    if values_bits[Constants::V_Type_of_BG] > 4.5 #Plain background
      if ratio == 1.0
        @width = 800
        @height = 800
      elsif ratio == 1.15
        @width=920
        @height=800
      elsif ratio == 1.33
        @width=930
        @height=700
      elsif ratio == 1.50
        @width=1050
        @height=700
      else
        @width=1200
        @height=700
      end
      
      if @vertical #if vertical is true, then the design is vertical oriented
        aux=@width
        @width=@height
        @height=aux
      end
    else #Picture as background
      if @main_image.vertical 
        @width = 900/(@main_image.height.to_f/@main_image.width.to_f)
        @height = 900
      else
        @width = 900
        @height = 900/(@main_image.width.to_f/@main_image.height.to_f)
      end
    end     
  end
  
  def generate_orientation
    if values_bits[Constants::V_Design_orientation]<4.5
      @vertical=false #Horizontal
    else
      @vertical=true #Vertial
    end   
  end
  
  def generate_ratio
    if values_bits[Constants::V_Design_ratio]==2
      @ratio=1
    elsif values_bits[Constants::V_Design_ratio]>2 and values_bits[Constants::V_Design_ratio]<4.5
      @ratio=1.15
    elsif values_bits[Constants::V_Design_ratio]==4.5
      @ratio=1.33
    elsif values_bits[Constants::V_Design_ratio]>4.5 and values_bits[Constants::V_Design_ratio]<6.5
      @ratio=1.50
    elsif values_bits[Constants::V_Design_ratio]==6.5
      @ratio=1.77
    end
    
  end
  
  #Are colors suitable?
  def improve_legibility
    @colors.length.times do |n|
      if n!=0 and not colors[0].is_contrasted_enough(colors[n])
        if not colors[0].is_contrasted_enough(colors[n]) and values_bits[Constants::V_Darkness]<=4.5
          colors[n]=colors[n].get_dark(20)
        elsif not colors[0].is_contrasted_enough(colors[n]) and values_bits[Constants::V_Darkness]>4.5
          colors[n]=colors[n].get_pale(90)
        end #if not end
    end#If end
    end#color.length do end
  end
  
  #Here is where it gets the main colors
  #from the main image
  def obtain_main_image_colors
    pic = ImageList.new(@main_image.source)
    pic.resize!(0.20)
    #Reducing picture colors
    pic = pic.quantize(5, Magick::RGBColorspace, 0, 0, false)  
    #By modulating them we get better colors
    pic = pic.modulate(1.2, 1.8, 1.0) #L S H
    #Background color will be the most used color in the picture
    color_pixels = pic.color_histogram
      
    max=0
    background_px = 0
    
    color_pixels.each do |k,v|
      if v >max
        max=v
        background_px = k
      end
    end   
    
    @image_colors << Colour.new(background_px.red, background_px.green, background_px.blue) #image_colors[0] is the background
    
    color_pixels.each do |k,v|
      hsl = k.to_hsla
      if hsl[2]>=35 and hsl[2]<=75
        @image_colors << Colour.new(k.red, k.green, k.blue)
      end
    end
    
    puts '......'
    puts @image_colors[0].red
    puts @image_colors[0].green
    puts @image_colors[0].blue
    
    @image_colors[1] = @image_colors[1]==nil ? @image_colors[0] : @image_colors[1]
    @image_colors[2] = @image_colors[2]==nil ? @image_colors[0] : @image_colors[2]

  end
  
  #The main Color function 
  def generate_color_scheme
    if values_bits[Constants::V_Use_of_colors]<=2.5 #No colors    
      if values_bits[Constants::V_Type_of_BG]<4.5 and @image_colors[0].get_lightness > Constants::Min_lightness#image as bg
        scheme = 'dark'
      elsif values_bits[Constants::V_Type_of_BG]<4.5 and @image_colors[0].get_lightness < Constants::Min_lightness
        scheme = 'light'
      elsif values_bits[Constants::V_Darkness]<=4.5#Light
        scheme = 'dark'
      elsif values_bits[Constants::V_Darkness]>=4.5#Dark
        scheme = 'light'
      end
      
      if scheme == 'dark'
        @colors[0]=Colour.new(255,255,255)
        @colors[1]=Colour.new
        @colors[2]=Colour.new
        @colors[3]=Colour.new
        @colors[4]=Colour.new(40,40,40)
        @colors[5]=Colour.new(55,55,55)
        @colors[6]=Colour.new(70,70,70)
        @colors[7]=Colour.new
      elsif scheme == 'light'
        @colors[0]=Colour.new
        @colors[1]=Colour.new(255,255,255)
        @colors[2]=Colour.new(255,255,255)
        @colors[3]=Colour.new(255,255,255)
        @colors[4]=Colour.new(240,240,240)
        @colors[5]=Colour.new(235,235,235)
        @colors[6]=Colour.new(230,230,230)
        @colors[7]=Colour.new(255,255,255)
      end
  
    else #Colors
      #Main color (colors[1] - colors[3])
      if values_bits[Constants::V_Main_color]<=2 #Complementary main pic
        @colors[1] = @image_colors[1].get_complementary
      elsif values_bits[Constants::V_Main_color]>2 and values_bits[Constants::V_Main_color]<=5 #Contrast main pic
        @colors[1] = @image_colors[1].get_contrasted
      elsif values_bits[Constants::V_Main_color]>5 and values_bits[Constants::V_Main_color]<=8 #main_pic
        @colors[1] = @image_colors[1]
      else #random
        @colors[1] = Colour.new.get_random_color()
      end
      @colors[2] = colors[1].get_lighter
      @colors[3] = colors[1].get_darker
      
      #Accent colors (colors[4] - colors[6])
      if values_bits[Constants::V_Accent_colors]<=2 #secondary
        accent_colors = @image_colors[2].get_analogous
        @colors[4]=@image_colors[2]
        2.times do |n|
          @colors[n+5] = accent_colors[n]
        end
      elsif values_bits[Constants::V_Accent_colors]>2 and values_bits[Constants::V_Accent_colors]<=4.5 #triadic
        accent_colors = colors[1].get_triadic
        3.times do |n|
          @colors[n+4] = accent_colors[n]
        end
      elsif values_bits[Constants::V_Accent_colors]>4.5 and values_bits[Constants::V_Accent_colors]<=8 #analogous
        accent_colors = colors[1].get_analogous
        3.times do |n|
          @colors[n+4] = accent_colors[n]
        end
      else #complementary
        @colors[4] = colors[1].get_complementary
        accent_colors = colors[4].get_analogous
        2.times do |n|
          @colors[n+5] = accent_colors[n]
        end
      end
     
      #Background color (colors[0])
      if values_bits[Constants::V_BG_color]<7 #Plain background
        if values_bits[Constants::V_Darkness]>4.5 #Dark design 
          @colors[0]=colors[1].get_dark
        else #Light design
          @colors[0]=colors[1].get_pale
        end
      else
        @colors[0]=Colour.new
      end
    
      #Text color (colors[7])
      if values_bits[Constants::V_Type_of_BG]>=4.5 #Contrast with plain background
        if values_bits[Constants::V_Darkness]<4.5 #Light bg
          @colors[7]=Colour.new
        else #Dark bg
          @colors[7]=Colour.new(255,255,255)
        end
      else #Contrast with picture as background
        if @image_colors[0].get_lightness > Constants::Min_lightness
          @colors[7]=Colour.new
        else
          @colors[7]=Colour.new(255,255,255)
        end
      end
    end
    
    @background = @colors[0]
  end
  
  def generate_text_backgrounds
    @colors.length.times do |n|
      if @colors[n].is_contrasted_enough(Colour.new(255,255,255))
        @bg_colors[n] = Colour.new(255,255,255)
      else
        @bg_colors[n] = Colour.new
      end
    end
  end
  
  def generate_predominant_shape
    if values_bits[Constants::V_Predominant_shape]<2
      @predominant_shape='curved'
    elsif values_bits[Constants::V_Predominant_shape]>2 and values_bits[Constants::V_Predominant_shape]<=4.5
      @predominant_shape='slightly_curved'
    elsif values_bits[Constants::V_Predominant_shape]>4.5 and values_bits[Constants::V_Predominant_shape]<=6.5
      @predominant_shape='slightly_straight'
    else
      @predominant_shape='straight'
    end  
  end
  
  def generate_family_fonts
    if values_bits[Constants::V_Primary_font_style]<2
      primary_font_style='graphic'
    elsif values_bits[Constants::V_Primary_font_style]>2 and values_bits[Constants::V_Primary_font_style]<6.5
      primary_font_style='script'
    else
      primary_font_style='others'
    end
    
    secondary_font_style='others'
    
    @primary_font=get_font_name(primary_font_style, predominant_shape)   #Gets the name of the font   
    
    if values_bits[Constants::V_Secondary_font_style]<4.5 #Repetition
      @secondary_font= @primary_font
    else
      if @predominant_shape == "curved" or @predominant_shape == "slightly_curved"
        @secondary_font=get_font_name(secondary_font_style, "straight")
      else
        @secondary_font=get_font_name(secondary_font_style, "curved")
      end
    end
  end
  
  def get_font_name(font_style, shape)
    possible_fonts = []
    doc = Document.new(File.new('public/xml/fonts.xml'))
    root=doc.root

    root.elements.each do |font|
      if font.attributes["type"]==font_style and font.attributes["shape"]==shape
        possible_fonts << font.attributes["name"]
      elsif font.attributes["type"]==font_style and (font_style=='graphic' or font_style=='script')
        possible_fonts << font.attributes["name"]
      end
    end
    
    return possible_fonts[rand(possible_fonts.length)]    
  end
  
  #Formatting the text...
  def generate_font(item)
    item.generate_font_size(values_bits)       #Size
    item.generate_font_weight(values_bits)     #Weight
    item.generate_font_filename(values_bits, primary_font, secondary_font)    #Font Face
    item.generate_font_color(values_bits[Constants::V_Use_of_colors], values_bits[Constants::V_Texts_BG], colors, bg_colors, values_bits[Constants::V_type_of_BG_decoration])
  end

  def composite_main_image_position
    if values_bits[Constants::V_Type_of_BG] > 4.5 #Plain background
      if values_bits[Constants::V_Image_position]< 4.5 #Normal composition (Left and Up)
        @main_image.x_pos = sides_img_margin
        @main_image.y_pos = upper_img_margin
      else #Alternative composition (Right and Down)
        if @vertical #Horizontal
          @main_image.x_pos = sides_img_margin
          @main_image.y_pos = @height - (upper_img_margin + @main_image.height)
        else #Vertical
          @main_image.x_pos = @width - (sides_img_margin + @main_image.width)
          @main_image.y_pos = upper_img_margin
        end
      end
    else # Picture as background
      @main_image.x_pos = 0
      @main_image.y_pos = 0
    end
  end
  
  def initialize_composition_values
    @groups.each do |g|
      g.calculate_sizes
    end
        
    #Interest box
    @interest_box = Group.new
    @interest_box.x_pos = @main_image.interest_box_x.to_i
    @interest_box.y_pos = @main_image.interest_box_y.to_i
    @interest_box.x_average_pos = @main_image.interest_box_average_x
    @interest_box.y_average_pos = @main_image.interest_box_average_y
    @interest_box.width = @main_image.interest_box_width.to_i
    @interest_box.height = @main_image.interest_box_height.to_i
    @interest_box.weight = @main_image.interest_box_width.to_i
    @interest_box.normal_group = false
  end
  
  #This returns the difference between 
  #free space and groups space
  def space_factor
    groups_area = values_bits[Constants::V_Type_of_BG] > 4.5 ? 0 : @interest_box.width * @interest_box.height
    @groups.each do |g|
      groups_area += g.width * g.height
    end
    white_space_area = @white_space_w * @white_space_h
    
    return groups_area/white_space_area
  end
  
  #Just in case there's too much white space...
  def adapt_design_size 
    hits = 0
    while space_factor < Constants::Min_allowed_factor and hits < 3
      if @vertical 
        @height /= Constants::Shrink_factor
        @height += @height%20 == 0 ? 0 : 20-@height%20
      elsif not @vertical
        @width /= Constants::Shrink_factor
        @width += @width%20 == 0 ? 0 : 20-@width%20
      end
      composite_main_image_position
      generate_white_spaces
      white_space_area = white_space_w * white_space_h
      hits +=1
    end
  end
  
  def enlarge_white_space(width_grow, height_grow)
    if height_grow!=0 
      @height += height_grow
      @height += @height%20 == 0 ? 0 : 20-@height%20
    elsif width_grow!=0
      @width += width_grow
      @width += @width%20 == 0 ? 0 : 20-@width%20
    end 
  
    composite_main_image_position
    generate_white_spaces
  end
  
  def reduce_font_size
    @groups.each do |g|
      g.items.each do |i|
        if i.instance_of? Letters
          if i.type<=1 #Title and subtitle
            i.font_size *= Constants::Shrink_font_factor_big
          else #Highlighted, Normal and Notes
            i.font_size *= Constants::Shrink_font_factor_small
          end
        end
      end
      g.calculate_sizes
    end
  end
  
  def calculate_interest_point
    randomization = Kernel.rand
    found = false
    n=0
    
    while not found
      if randomization <= @main_image.rndm_interest[n][0] 
        found = true
        @interest_point[0] = @main_image.rndm_interest[n][1]
        @interest_point[1] = @main_image.rndm_interest[n][2]
      end
      n+=1
    end
  end
  
  def create_arguments(current_solution)
    args = ''
    args += @white_space_x.to_i.to_s+' '+@white_space_y.to_i.to_s+' '+@white_space_w.to_i.to_s+' '+@white_space_h.to_i.to_s+' ' 
    args += @interest_box.x_pos.to_i.to_s+' '+@interest_box.y_pos.to_i.to_s+' '+@interest_box.width.to_i.to_s+' '+@interest_box.height.to_i.to_s+' '
    args += values_bits[Constants::V_Type_of_BG] > 4.5 ? '1 ' : '0 ' #1, plain bg. 0, image as bg
    args += @vertical ? '1 ' : '0 ' #1, Vertical; 0, horizontal
    
    current_solution.each do |g|
      args += g.weight.to_i.to_s+' '+g.x_pos.to_i.to_s+' '+g.y_pos.to_i.to_s+' '+g.width.to_i.to_s+' '+g.height.to_i.to_s+' '
      args += g.x_average_pos.to_i.to_s+' '+g.y_average_pos.to_i.to_s+' '
      args += g.normal_group ? '1 ' : '0 '
    end
    
    return args
  end
  
  #This is where the C application is executed
  def start_simulated_annealing(args)
    #The app's output is saved in "result" variable
    result = `./app/models/C/simulated_annealing #{args}`
    result_array = result.split(' ')
    
    return result_array
  end
  
  #This is where the composition begins
  def start_composition
    current_solution = generate_initial_solution
    calculate_weight(current_solution)
    args = create_arguments(current_solution)
    result_array = start_simulated_annealing(args)
    
    solution_cost = result_array[result_array.length-3].to_f
    width_grow = result_array[result_array.length-2].to_i
    height_grow = result_array[result_array.length-1].to_i
    if(width_grow!=0 or height_grow !=0)
      enlarge_white_space(width_grow, height_grow)
    end
    times_to_try = 3
    
    while solution_cost > 1.0 and times_to_try>0 
      if values_bits[Constants::V_Type_of_BG]<=4.5
        reduce_font_size
      end
      
      current_solution = generate_initial_solution
      calculate_weight(current_solution)
      
      args = create_arguments(current_solution)
      result_array = start_simulated_annealing(args)
      
      solution_cost = result_array[result_array.length-3 ].to_f
      
      times_to_try -= 1
    end

    loop_n = (result_array.length - 2)/3 
    
    loop_n.times do |n|
      @groups[n].x_pos = result_array[0+n*3].to_i;
      @groups[n].y_pos = result_array[1+n*3].to_i;
      @groups[n].alignment = result_array[2+n*3].to_i==0 ? 'right' : 'left';
    end

    if values_bits[Constants::V_Type_of_BG] > 4.5
      cut_white_space_edges
    end

    @groups.length.times do |n|
      @groups[n].process_texts_position(@width)
    end
    
  end

  #Removes the free space near the edges
  def cut_white_space_edges
    x1_array = Array.new
    x2_array = Array.new
    y1_array = Array.new
    y2_array = Array.new
  
    @groups.each do |g|
      x1_array << g.x_pos
      x2_array << g.x_pos + g.width
      y1_array << g.y_pos
      y2_array << g.y_pos + g.height
    end
    
    if @vertical
      #Normal position of the image (up)
      if values_bits[Constants::V_Image_position]< 4.5 
        @height = y2_array.max + @upper_margin
      #Alternative position(down)
      else  
        new_height = @height - (y1_array.min-@upper_margin)
        
        @groups.each do |g|
          g.y_pos -= (@height - new_height)
        end
        @main_image.y_pos -= (@height - new_height)
        
        @height = new_height
      end
    else
      #Normal position of the image (left)
      if values_bits[Constants::V_Image_position]< 4.5
        @width = x2_array.max + @sides_margin
      #Alternative position of the image (right)
      else  
        new_width = @width - (x1_array.min-@sides_margin)
        
        @groups.each do |g|
          g.x_pos -= (@width - new_width)
        end
        @main_image.x_pos -= (@width - new_width)
        
        @width = new_width
      end
    end
  end

  #This just puts the groups one after another
  #and this becomes the initial solution 
  def generate_initial_solution
    aux_groups = @groups.groups_deep_clone
    x=@white_space_x
    y=@white_space_y
    
    aux_groups.each do |g|
      g.allocate_this(x,y)
      y+=g.height
    end
    
    if values_bits[Constants::V_Type_of_BG] <= 4.5 #Image as background
      aux_groups << @interest_box
    end
    
    return aux_groups
  end

   
  def calculate_weight(groups_array)
    groups_array.each do |g|
      if g.normal_group
        g.calculate_weight
      end
    end
  end

  #Depending on the margin, image size and
  #document size, this generates the 
  #free space of the document
  def generate_white_spaces
    #Plain background
    if values_bits[Constants::V_Type_of_BG] > 4.5 
      if @vertical
        @white_space_w = @width - @sides_margin*2  
        @white_space_h = @height - (@main_image.height + @upper_img_margin + @upper_margin*2)
        @white_space_x = @sides_margin
        @white_space_y = values_bits[Constants::V_Image_position] < 4.5 ? @main_image.height+@upper_margin+@upper_img_margin : @upper_margin
      else
        @white_space_w = @width - (@main_image.width + @sides_img_margin + @sides_margin*2)
        @white_space_h = @height - @upper_margin*2
        @white_space_x = values_bits[Constants::V_Image_position] < 4.5 ? @main_image.width+2*@sides_margin : @sides_margin
        @white_space_y = @upper_margin
      end
    #Image as background
    else 
      @white_space_w= @width - @sides_margin*2
      @white_space_h= @height - @upper_margin*2
      @white_space_x= @sides_margin
      @white_space_y= @upper_margin
    end
    
    @max_width = (@white_space_w.to_f * 0.60).to_i 
    @max_width -= max_width%20 == 0 ? 0 : max_width%20
    # @groups.each do |g|
    #   g.max_width = @max_width
    # end
  end
  
  #Here the XML is created
  def get_xml
    header = "<DESIGN></DESIGN>"
    path = 'public/users_xml/'+@visitor_id+'.xml'
    f = File.new(path, 'w+')  
    f.write header  
    f.close
        
    doc = Document.new File.new(path)
    root = doc.root
    
    ###Genes
    gen_bits_string = ''
    gen_bits.each do |g|
      gen_bits_string += g.to_s
    end
    
    genes = Element.new "genes"
    genes.attributes["string"] = gen_bits_string
    
    root.add_element genes
    
    ###Colors
    foreground = Element.new "foreground"
    @colors.length.times do |n|
      color = Element.new "fg_color"
      color.attributes["red"]= @colors[n].red.to_s
      color.attributes["green"]= @colors[n].green.to_s
      color.attributes["blue"]= @colors[n].blue.to_s
      color.attributes["n"]=n.to_s
      
      foreground.add_element color
    end
    root.add_element foreground
    
    background = Element.new "background"
    @bg_colors.length.times do |n|
      color = Element.new "bg_color"
      color.attributes["red"]= @bg_colors[n].red.to_s
      color.attributes["green"]= @bg_colors[n].green.to_s
      color.attributes["blue"]= @bg_colors[n].blue.to_s
      color.attributes["n"]=n.to_s
      
      background.add_element color
    end
    root.add_element background
    
    ###Fonts
    fonts = Element.new "fonts"

    p = Element.new "font"
    p.attributes["type"] = "primary"
    p.attributes["font"] = @primary_font 
    fonts.add_element p
    s = Element.new "font"
    s.attributes["type"] = "secondary"
    s.attributes["font"] = @secondary_font
    fonts.add_element s
    
    root.add_element fonts
    
    File.open(path, 'w') do |f|  
       f.puts root  
    end

    return path
    
  end

end #Class end





