#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

#This class receives a design object
#and it creates the final output image
class Compositor
  attr_accessor :sketch, :design
  
  def create_png(design)
    @design=design
    
    @sketch = Image.new(@design.width, @design.height){ self.background_color=design.background.get_pixel}
    
    add_picture(@design.main_image)
    design.groups.each do |group|
      group.items.each do |item|
        if item.instance_of? Letters 
          add_text(item)
        end
        if group.has_image
          add_picture(group.text_image)
        end
      end
    end
    
    factor = @design.width>@design.height ? 150.0/@design.width : 150.0/@design.height
    
    big = 'designs/'+@design.visitor_id+'_'+get_number(@design.current_number)+'.png'
    thumb = 'designs/'+@design.visitor_id+'_'+get_number(@design.current_number)+'_thumb.png'
    
    @sketch.write('public/images/designs/'+@design.visitor_id+'_'+get_number(@design.current_number)+'.png')
    @sketch_thumb = sketch.resize(factor)
    @sketch_thumb.write('public/images/designs/'+@design.visitor_id+'_'+get_number(@design.current_number)+'_thumb.png')
    
    return [big, thumb]
  end
  
  def get_number(number)
    n = number.to_s
    n = '0'*(Constants::Zeros-n.length)+n
  end
  
  def add_text(item)
    text = Draw.new
    text.annotate(@sketch, 0, 0, item.x_pos, item.y_pos, item.content) {
        self.pointsize = item.font_size.to_i
        self.font = item.font_filename
        self.stroke = 'transparent'
        #Alignment
        if item.alignment == 'left'
          self.gravity = Magick::NorthWestGravity
        else
          self.gravity = Magick::NorthEastGravity
        end
        #Background
        if item.has_background
          p = Pixel.new(item.fill_color.red, item.fill_color.green, item.fill_color.blue)
          self.undercolor = p
          self.fill = '#'+item.bg_color.value_hex.to_s
        elsif item.has_border  
          p = Pixel.new(item.bg_color.red, item.bg_color.green, item.bg_color.blue)
          self.stroke_width = item.type != 0 ? 1 : 2
          self.stroke = '#'+item.fill_color.value_hex.to_s
          self.fill = p
        else 
          self.fill = '#'+item.fill_color.value_hex.to_s
        end
        #Font weight
        if item.font_weight=='light'
          self.font_weight = Magick::LighterWeight
        elsif item.font_weight=='bold' or item.font_weight=='semibold'
          self.font_weight = Magick::BoldWeight
        elsif item.font_weight=='black'
          self.font_weight = Magick::BolderWeight
        else
          self.font_weight = Magick::NormalWeight
        end
    }
    
  end
  
  def add_picture(item)
    pic = Image.read(item.source).first
    pic.resize!(item.width, item.height,LanczosFilter, 1.0)
    
    @sketch.composite!(pic, item.x_pos, item.y_pos, OverCompositeOp)
  end
  
end



