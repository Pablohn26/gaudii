#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

#A design has many groups,
#and each group has many items
class Group < Array
  attr_accessor :items, :width, :height, :weight, :vertical_spaces, :has_image
  attr_accessor :x_pos, :y_pos, :x_average_pos, :y_average_pos, :normal_group, :alignment, :text_image
  
  def initialize()
    @items = []
    @vertical_spaces = Array.new
    @weight = 0
    @normal_group = true
    @alignment = 'left'
    @has_image = false
  end
  
  def add_item(item)
    @items << item
  end
  
  def calculate_weight
    @weight = 0
    @items.each do |i|
      if i.instance_of? Letters
        @weight += i.calculate_weight
      end
    end
    
    if @has_image
      @weight += 30
    end
    
  end
  
  def calculate_sizes
    #Text Height & Width
    @height = 0
    horizontal_sizes = Array.new
    @vertical_spaces = Array.new
    
    @items.each do |i|
      @height += i.font_size
      text_box = get_text_box(i)
      horizontal_sizes << text_box[0]
      @vertical_spaces << text_box[1]
    end
    
    partial_height = @height
    
    (@vertical_spaces.length-1).times do |n|
      @height += @vertical_spaces[n]
    end
    
    @width = horizontal_sizes.max
        
    #In case there is an image
    if @has_image
      new_image_height = @height < Constants::Min_text_image_size ? Constants::Min_text_image_size : partial_height.to_f*1.10
      new_image_height += new_image_height%20==0 ? 0 : 20-new_image_height%20
      new_image_width = (new_image_height.to_f/@text_image.height.to_f)*@text_image.width.to_f
      @text_image.width = new_image_width.to_i
      @text_image.height = new_image_height.to_i
      
      @width += @text_image.width + Constants::Margin_text_pics
      @height += @text_image.height>@height ? @text_image.height-@height : 0
    end
    
    @width += @width%20 != 0 ? (20 - @width%20) : 0 
    
  end
  
  def get_text_box(item)
    aux = Image.new(200, 200)
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
    item.text_width = metrics.width
    item.text_height = metrics.height 
    
    return [item.text_width, item.text_height]
  end
  
  def allocate_this(x,y)
    @x_pos = x
    @y_pos = y
    #We too calculate the average point
    @x_average_pos = x + @width/2
    @y_average_pos = y + @height/2
  end

  #Once we have the group position, we process
  #the position for every item in it.
  def process_texts_position(design_width)
    #We too calculate the average point
    @x_average_pos = @x_pos + @width/2
    @y_average_pos = @y_pos + @height/2
    
    if @alignment == 'left'
      text_x_pos = @x_pos
      if @has_image
        text_x_pos += @text_image.width + Constants::Margin_text_pics
        @text_image.x_pos = @x_pos
      end
    else 
      text_x_pos = design_width - (@x_pos + @width)
      if @has_image
        text_x_pos +=  @text_image.width + Constants::Margin_text_pics 
        @text_image.x_pos = (@x_pos+@width)-@text_image.width
      end
    end
    
    if @has_image
      @text_image.y_pos = @y_pos
    end
    text_y_pos = @y_pos
    @items.length.times do |n|
      @items[n].x_pos = text_x_pos
      @items[n].y_pos = text_y_pos
      @items[n].alignment = @alignment

      text_y_pos += @vertical_spaces[n]
    end
    
  end

  
end






