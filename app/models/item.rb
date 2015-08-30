#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

class Item
  attr_accessor :x_pos, :y_pos, :type
    
end

#Fonts class
class Letters < Item
  attr_accessor :font_size, :font_filename, :font_weight, :fill_color, :alignment
  attr_accessor :content, :bg_color, :has_background, :has_border, :text_width, :text_height

  def initialize(type=0, content='0')
    @type= type
    @content = content
    @has_background = false
    @has_border = false
    @y_pos = 20
    @x_pos = 20
  end
    
  def calculate_weight
    if type==0
      return 60
    elsif type==1
      return 40
    elsif type==2
      return 20
    elsif type==3
      return 10
    elsif type==4
      return 5
    end
  end
  
  def adjust_font_size(item, max_width)
    aux = Image.new(max_width, 800)
    initial_size = item.font_size
    text = Draw.new
    text.annotate(aux, 0, 0, 0, 0, item.content) do
        text.font = item.font_filename
        text.pointsize = item.font_size
        #Font weight
        if item.font_weight=='light'
          text.font_weight = Magick::LighterWeight
        elsif item.font_weight=='bold' or item.font_weight=='semibold'
          text.font_weight = Magick::BoldWeight
        elsif item.font_weight=='black'
          text.font_weight = Magick::BolderWeight
        else
          text.font_weight = Magick::NormalWeight
        end      
    end    
  
    metrics = text.get_multiline_type_metrics(aux, item.content)
    font_w = metrics.width
    while font_w > max_width
      #Size adjustment
      if font_w - max_width > 300
        item.font_size -= 10
      elsif font_w - max_width > 150
        item.font_size -= 7
      elsif font_w - max_width > 50
        item.font_size -= 4
      else
        item.font_size -= 2
      end
      
      text = Draw.new
      text.annotate(aux, 0, 0, 0, 0, item.content) do
          text.font = item.font_filename
          text.pointsize = item.font_size
          #Font weight
          if item.font_weight=='light'
            text.font_weight = Magick::LighterWeight
          elsif item.font_weight=='bold' or item.font_weight=='semibold'
            text.font_weight = Magick::BoldWeight
          elsif item.font_weight=='black'
            text.font_weight = Magick::BolderWeight
          else
            text.font_weight = Magick::NormalWeight
          end      
      end    
    
      metrics = text.get_multiline_type_metrics(aux, item.content)
      font_w = metrics.width
    
    end
    
    return item.font_size 
  end
  
  def adapt_font_size(ratio)
    self.font_size = (self.font_size*ratio).to_i
  end
  
  def generate_font_filename(values_bits, primary, secondary)
    if values_bits[Constants::V_Secondary_font_style]<4.5 #No contrast between font faces
      @font_filename=get_font_filename(primary)
    else #Contrast between font faces
      if type==0
        @font_filename=get_font_filename(primary)
      elsif type==1
        @font_filename=get_font_filename(secondary)
      elsif type==2
        @font_filename=get_font_filename(secondary)
      elsif type==3
        @font_filename=get_font_filename(secondary)
      else
        @font_filename=get_font_filename(secondary)
      end
    end
  end
  
  def get_font_filename(name)
    doc = Document.new(File.new('public/xml/fonts.xml'))
    root=doc.root
    filename = 'Error'
    root.elements.each do |font|
      if font.attributes["name"]==name 
        filename = font.attributes["filename"]
      end
    end
    return filename
  end
  
  #This function also puts text in caps.
  def generate_font_size(values_bits)
    if type == 0 #h0
      @font_size=values_bits[Constants::V_Size_h0].to_i
      if values_bits[Constants::V_All_caps]>4.5
        @content.upcase!
      end
    elsif type == 1 #h1
      @font_size=values_bits[Constants::V_Size_h1].to_i
      if values_bits[Constants::V_All_caps]>7.5
        @content.upcase!
      end
    elsif type == 2 #h2
      @font_size=values_bits[Constants::V_Size_h2].to_i
    elsif type == 3 #h3
      @font_size=values_bits[Constants::V_Size_h3].to_i
    elsif type == 4 #h4
      @font_size=values_bits[Constants::V_Size_h4].to_i
    end
  end
  
  def generate_font_weight(values_bits)
    if type == 0 #h0
      @font_weight=num_to_weight(values_bits[Constants::V_Weight_h0])
    elsif type == 1 #h1
      @font_weight=num_to_weight(values_bits[Constants::V_Weight_h1])
    elsif type == 2 #h2
      @font_weight=num_to_weight(values_bits[Constants::V_Weight_h2])
    elsif type == 3 #h3
      @font_weight=num_to_weight(values_bits[Constants::V_Weight_h3])
    elsif type == 4 #h4
      @font_weight=num_to_weight(values_bits[Constants::V_Weight_h4])
    end
  end
  
  def generate_font_color(use_of_colors, use_of_bg, colors_array, bg_colors_array, bg_decoration)
    #Fill color
    if use_of_colors <=7 #Medium use of colors
      if type == 0 #h0
        @fill_color = colors_array[1]
        @bg_color = bg_colors_array[1]
      elsif type == 1 #h1
        @fill_color = colors_array[4]
        @bg_color = bg_colors_array[4]
      elsif type == 2 #h2
        @fill_color = colors_array[1]
        @bg_color = bg_colors_array[1]
      elsif type == 3 #h3
        @fill_color = colors_array[7]
        @bg_color = bg_colors_array[7]
      elsif type == 4 #h4
        @fill_color = colors_array[7]
        @bg_color = bg_colors_array[7]
      end
    else #High use of colors
      if type == 0 #h0
        @fill_color = colors_array[1]
        @bg_color = bg_colors_array[1]
      elsif type == 1 #h1
        @fill_color = colors_array[rand(3)+4]
        @bg_color = bg_colors_array[4]
      elsif type == 2 #h2
        @fill_color = colors_array[rand(3)+4]
        @bg_color = bg_colors_array[4]
      elsif type == 3 #h3
        @fill_color = colors_array[7]
        @bg_color = bg_colors_array[7]
      elsif type == 4 #h4
        @fill_color = colors_array[7]
        @bg_color = bg_colors_array[7]
      end
    end
    
    #Background color
    if use_of_bg > 3.5 and use_of_bg <= 6.5
      if type == 0 #h0
        @has_background = bg_decoration < 4.5 ? true : false
        @has_border = bg_decoration >= 4.5 ? true : false
      elsif type == 1 #h1
        @has_background = bg_decoration < 4.5 ? true : false
      end
    elsif use_of_bg > 6.5
      if type == 0 #h0
        @has_background = bg_decoration < 4.5 ? true : false
      elsif type == 1 #h1
        @has_background = bg_decoration < 4.5 ? true : false
      elsif type == 2 #h2
        @has_background = bg_decoration < 4.5 ? true : false
      end
    else
      @has_background=false
    end
  end
  
  def num_to_weight(num)
    if num<1.5 #Light
      'light'
    elsif num>=1.5 and num<3.5 #Normal
      'normal'
    elsif num>=3.5 and num<5.5 #Semibold
      'semibold'
    elsif num>=5.5 and num<7.5 #Bold
      'bold'
    else #Black
      'black' 
    end
  end

end

#Images class
class DesignImage < Item
  attr_accessor :source, :zooming_h, :zooming_v, :width, :height, :vertical
  attr_accessor :interest_box_x,:interest_box_y,:interest_box_width,:interest_box_height
  attr_accessor :sectors_addr, :sectors_membership, :interest_box_average_x, :interest_box_average_y
  attr_accessor :rndm_interest, :interest_box_weight, :analysis

  def initialize(source, type)
    @source = source
    @type = type
    @sectors_addr = {}
    @sectors_membership = {}
    @rndm_interest = []
    generate_sizes
  end

  def generate_sizes
    pic = ImageList.new(@source).first
    @width = pic.columns.to_i
    @height = pic.rows.to_i
    if @width > @height
      @vertical = false
    else
      @vertical = true
    end
  end
  
  def add_interest_spot(x,y,w,h, already_cropped=false)
    @interest_box_x = x
    @interest_box_y = y
    @interest_box_width = w
    @interest_box_height = h
    @interest_box_average_x = x + w/2
    @interest_box_average_y = y + h/2
    
    analyze_interest_spot
    if not already_cropped
      create_cropped_versions
    end
  end
  
  def analyze_interest_spot
    define_sectors
    define_membership_degree
    analyze_membership_degree
    analyze_interest_box_weight    
  end
  
  def create_cropped_versions
    aux = 0
    key = :t_a
    @sectors_membership.each do |k, v|
      if aux < v
        key = k
        aux = v
      end
    end

    if not(key == :e_left or key == :e_right or key == :e_up or key == :e_down)
      left_grow = @interest_box_x
      right_grow = @width-(@interest_box_x+@interest_box_width)
      up_grow = @interest_box_y
      down_grow = @height-(@interest_box_y+@interest_box_height)
      
      #Horizontal growth
      if @interest_box_width > @interest_box_height
        v_crop_x = @interest_box_x - left_grow/Constants::Big_step
        v_crop_width = @interest_box_width + (@interest_box_x-v_crop_x) + right_grow/Constants::Big_step
        v_crop_y = @interest_box_y - up_grow/Constants::Medium_step
        v_crop_height = @interest_box_height + (@interest_box_y-v_crop_y) + down_grow/Constants::Medium_step
      else
        v_crop_x = @interest_box_x - left_grow/Constants::Big_step
        v_crop_width = @interest_box_width + (@interest_box_x-v_crop_x) + right_grow/Constants::Big_step
        v_crop_y = @interest_box_y - up_grow/Constants::Small_step
        v_crop_height = @interest_box_height + (@interest_box_y-v_crop_y) + down_grow/Constants::Small_step
      end
      
      #Vertical Growth
      if @interest_box_height > @interest_box_width
        h_crop_x = @interest_box_x -left_grow/Constants::Medium_step
        h_crop_width = @interest_box_width + (@interest_box_x-h_crop_x) + right_grow/Constants::Medium_step
        h_crop_y = @interest_box_y -up_grow/Constants::Big_step
        h_crop_height = @interest_box_height + (@interest_box_y-h_crop_y) + down_grow/Constants::Big_step
      else
        h_crop_x = @interest_box_x -left_grow/Constants::Small_step
        h_crop_width = @interest_box_width + (@interest_box_x-h_crop_x) + right_grow/Constants::Small_step
        h_crop_y = @interest_box_y - up_grow/Constants::Big_step
        h_crop_height = @interest_box_height + (@interest_box_y-h_crop_y) + down_grow/Constants::Big_step
      end

      #Now we do the cropping
      original = Magick::ImageList.new(@source)
      crop_v = original.crop(v_crop_x, v_crop_y, v_crop_width, v_crop_height)
      crop_h = original.crop(h_crop_x, h_crop_y, h_crop_width, h_crop_height)
      
      source_v = @source.gsub('.', '_v.')
      source_h = @source.gsub('.', '_h.')
  
      crop_v.write(source_v)
      crop_h.write(source_h)

      @zooming_v = DesignImage.new(source_v, 0)
      @zooming_v.add_interest_spot(@interest_box_x-v_crop_x, @interest_box_y-v_crop_y, @interest_box_width, @interest_box_height, true)
      @zooming_h = DesignImage.new(source_h, 0)
      @zooming_h.add_interest_spot(@interest_box_x-h_crop_x, @interest_box_y-h_crop_y, @interest_box_width, @interest_box_height, true)

    end

  end
  
  
  def analyze_interest_box_weight
    @interest_box_weight = 100
  end
  
  def define_sectors
    #Every sector is an array with this structure: [x, y, width, height]
    #Edge sectors
    @sectors_addr[:e_left] =   [0,0, 0.25*@width, @height]               #LEFT - [0]
    @sectors_addr[:e_right] =  [0.75*@width, 0, 0.25*@width, @height]   #RIGHT - [1]
    @sectors_addr[:e_up] =     [0,0, @width, 0.25*@height]               #UP - [2]
    @sectors_addr[:e_down] =   [0,0.75*@height, @width, 0.25*@height]    #DOWN - [3]
    
    #Rule of thirds sectors
    @sectors_addr[:t_a] = [0.20*@width, 0.20*@height, 0.25*@width, 0.25*@height] #A (up-left) - [4]
    @sectors_addr[:t_b] = [0.55*@width, 0.20*@height, 0.25*@width, 0.25*@height] #B (up-right) - [5]
    @sectors_addr[:t_c] = [0.20*@width, 0.55*@height, 0.25*@width, 0.25*@height] #C (down-left) - [6]
    @sectors_addr[:t_d] = [0.55*@width, 0.55*@height, 0.25*@width, 0.25*@height] #D (down-right) - [7]
    
    #Centered sector
    @sectors_addr[:c_up] =       [0.4*@width, 0, 0.2*@width, 0.4*@height]            #UP  - [8]
    @sectors_addr[:c_down] =     [0.4*@width, 0.6*@height, 0.2*@width, 0.4*@height]  #DOWN - [9]
    @sectors_addr[:c_middle] =   [0*4*@width, 0.4*@height, 0.2*@width, 0.2*@height]  #MIDDLE - [10]
    @sectors_addr[:c_left] =     [0, 0.4*@height, 0.4*@width, 0.2*@height]            #LEFT - [11]
    @sectors_addr[:c_right] =    [0*6*@width, 0.4*@height, 0.4*@width, 0.2*@height]  #RIGHT - [12] 
  end
  
  def define_membership_degree
    interest_box_area = @interest_box_height * @interest_box_width
    xs = (@interest_box_x.to_i..(@interest_box_x+@interest_box_width).to_i)
    ys = (@interest_box_y.to_i..(@interest_box_y+@interest_box_height).to_i)
    
    @sectors_addr.each do |k,s|
      this_sector_xs = (s[0].to_i..(s[0]+s[2]).to_i)
      this_sector_ys = (s[1].to_i..(s[1]+s[3]).to_i)
      this_sector_area = s[2]*s[3]
      #Width
         if this_sector_xs.include?(xs.min) and this_sector_xs.include?(xs.max)
           partial_width = xs.max - xs.min
         elsif this_sector_xs.include?(xs.min) and not this_sector_xs.include?(xs.max)
           partial_width = this_sector_xs.max - xs.min
         elsif not this_sector_xs.include?(xs.min) and this_sector_xs.include?(xs.max)
           partial_width = xs.max - this_sector_xs.min
         elsif xs.include?(this_sector_xs.min) and xs.include?(this_sector_xs.max)
           partial_width = this_sector_xs.max - this_sector_xs.min
         else
           partial_width = 0.0
         end
      #Height
      if this_sector_ys.include?(ys.min) and this_sector_ys.include?(ys.max)
        partial_height = ys.max - ys.min
      elsif this_sector_ys.include?(ys.min) and not this_sector_ys.include?(ys.max)
        partial_height = this_sector_ys.max - ys.min
      elsif not this_sector_ys.include?(ys.min) and this_sector_ys.include?(ys.max)
        partial_height = ys.max - this_sector_ys.min
      elsif ys.include?(this_sector_ys.min) and ys.include?(this_sector_ys.max)
        partial_height = this_sector_ys.max - this_sector_ys.min
      else
        partial_height = 0.0
      end
      
      @sectors_membership[k]= (partial_width*partial_height).to_f/this_sector_area.to_f
      # puts k.to_s+"  "+@sectors_membership[k].to_s
    end
  end  
  
  def analyze_membership_degree
    sum = 0
    
    @sectors_membership.each do |k, v|
      sum += v>=0.10 ? v : 0
    end
    
    @rndm_interest[0] = [0.80, @interest_box_x+@interest_box_width/2, @interest_box_y+@interest_box_height/2]
    
    @sectors_membership.each do |k, v|
      if v>=0.10
        random_factor = 0.80 + (0.20*(v/sum))
        @rndm_interest << [ random_factor, @sectors_addr[k][0]+@sectors_addr[k][2]/2, @sectors_addr[k][1]+@sectors_addr[k][3]/2]       
      end
    end
    
    @rndm_interest << [1.0, @interest_box_x+@interest_box_width/2, @interest_box_y+@interest_box_height/2]
    
  end
  
  def readapt_interest_box(factor)
    @interest_box_x *= factor
    @interest_box_y *= factor
    @interest_box_width *= factor
    @interest_box_height *= factor
    @interest_box_average_x *= factor
    @interest_box_average_y *= factor
  end
  
end

