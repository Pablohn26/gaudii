#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

#Main class for creatins colors
class Colour
  attr_accessor :value_hex, :red, :green, :blue 
  
  def initialize(red=0,green=0,blue=0)
    @red= red.to_i
    @green= green.to_i
    @blue= blue.to_i
    @value_hex= dec_to_hex
  end
  
  def get_pixel
    return Pixel.new(@red, @green, @blue)
  end
  
  def get_lightness
    hsl = rgb_to_hsl
    return hsl[2]
  end
  
  def dec_to_hex
    hex_array = []
    hex_array << @red.to_s(16)
    hex_array << @green.to_s(16)
    hex_array << @blue.to_s(16)
    
    3.times do |value|
      if hex_array[value].length==1
        hex_array[value]='0'+hex_array[value]
      end
      hex_array[value].upcase!
    end
    
    hex_array.join
  end
  
  def hex_to_dec (hex)
     r_hex = hex.slice(0..1)
     g_hex = hex.slice(2..3)
     b_hex = hex.slice(4..5)
     
     rgb = []
     
     rgb << r_hex.hex.to_i
     rgb << g_hex.hex.to_i
     rgb << b_hex.hex.to_i
     
     return rgb
  end
  
  def rgb_to_hsl
    aux_pixel = Pixel.new(@red,@green,@blue)
    hsl=aux_pixel.to_hsla
    hsl.delete(hsl.last)
    
    return hsl    
  end
  
  def hsl_to_rgb(hsl)
    aux_pixel = Pixel.from_hsla(hsl[0],hsl[1],hsl[2],0.0)
    
    return [aux_pixel.red,aux_pixel.green,aux_pixel.blue]
  end
  
  def get_lighter(amount=1.2)
    hsl = rgb_to_hsl
    
    hsl[2]*=amount
    hsl[2] = hsl[2]>1.0? 1.0 : hsl[2]
    
    rgb = hsl_to_rgb(hsl)
    return Colour.new(rgb[0],rgb[1],rgb[2])
  end

  def get_darker(amount=0.8)
    hsl = rgb_to_hsl 
    hsl[2]*=amount
    
    rgb = hsl_to_rgb(hsl)
    return Colour.new(rgb[0],rgb[1],rgb[2])
  end

  def get_pale(amount=94)
    hsl = rgb_to_hsl
    hsl[2]=amount
    rgb = hsl_to_rgb(hsl)
    return Colour.new(rgb[0],rgb[1],rgb[2])
  end

  def get_dark(amount=15)
    hsl = rgb_to_hsl
    hsl[2]=amount
    rgb = hsl_to_rgb(hsl)
    return Colour.new(rgb[0],rgb[1],rgb[2])
  end

  def get_desaturated
    hsl = rgb_to_hsl
    hsl[1]=0.0
    rgb = hsl_to_rgb(hsl)
    return Colour.new(rgb[0],rgb[1],rgb[2])
  end

  def is_contrasted_enough(color)
    red_dif = [color.red,red].max - [color.red,red].min
    green_dif = [color.green,green].max - [color.green,green].min
    blue_dif = [color.blue,blue].max - [color.blue,blue].min
    color_dif = red_dif + blue_dif + green_dif > 330
    
    lightness_1 = (299*red + 587*green + 114*blue)/1000
    lightness_2 = (299*color.red + 587*color.green + 114*color.blue)/1000
    lightness_dif = ([lightness_1, lightness_2].max - [lightness_1, lightness_2].min) > 100
    
    return (color_dif and lightness_dif)
  end

  def get_contrasted
    hsl = rgb_to_hsl
    
    contrasted_color = get_random_color
    if hsl[2]>60 #Bright color
      contrasted_color=contrasted_color.get_dark(20)
    else#Dark color
      contrasted_color=contrasted_color.get_pale(94)
    end
    
    contrasted_color
  end

  def get_random_color
    sector = get_sector_info_by_hsl(Kernel.rand(360))
    position = Kernel.rand(30)
    hue = sector[1] + ((sector[1]-sector[2]).abs/30.0)*position
    
    if sector[3]>sector[4] #Saturation
      saturation = sector[3] - ((sector[3]-sector[4]).abs/30.0)*position
    else
      saturation = sector[3] + ((sector[3]-sector[4]).abs/30.0)*position
    end
    
    if sector[5]>sector[6] #Brightness
      lightness = sector[5] - ((sector[5]-sector[6]).abs/30.0)*position
    else
      lightness = sector[5] + ((sector[5]-sector[6]).abs/30.0)*position
    end
    rgb = hsl_to_rgb([hue, saturation, lightness])
    
    return Colour.new(rgb[0],rgb[1],rgb[2])
  end

  def get_complementary
    return jump_to_color(6)
  end
  
  def get_analogous
    colors_array = []
    colors_array << jump_to_color(1)
    colors_array << jump_to_color(11)
    colors_array << jump_to_color(2)
    colors_array << jump_to_color(10)
    return colors_array
  end
  
  def get_triadic
    colors_array = []
    colors_array << jump_to_color(7)
    colors_array << jump_to_color(5)
    colors_array << jump_to_color(4)
    return colors_array
  end
  
  def get_tetradic
    colors_array = []
    colors_array << jump_to_color(7)
    colors_array << jump_to_color(6)
    colors_array << jump_to_color(1)
    return colors_array
  end

  #Having a jump, this function returns the color
  #which is at that distance
  def jump_to_color(distance)
    current_hsl = rgb_to_hsl
    new_hsl = []
    current_sector=get_sector_info_by_hsl(current_hsl[Constants::HSL_H])
    new_sector=get_sector_info_by_sector((current_sector[Constants::Col_number]+distance)%12)
    
    divisor=(current_sector[Constants::Col_max_H]-current_sector[Constants::Col_min_H])/30.0
    current_position=(current_hsl[Constants::HSL_H]-current_sector[Constants::Col_min_H])/divisor
    
    saturation_difference = current_hsl[Constants::HSL_S]/((current_sector[Constants::Col_min_S]+current_sector[Constants::Col_max_S])/2) 
    lightness_difference = current_hsl[Constants::HSL_L]/((current_sector[Constants::Col_min_L]+current_sector[Constants::Col_max_L])/2)
    
    #Hue
    new_hsl[Constants::HSL_H]=new_sector[Constants::Col_min_H]+((new_sector[Constants::Col_max_H]-new_sector[Constants::Col_min_H]).abs/30.0)*current_position
    #Saturation
    if new_sector[Constants::Col_min_S]>new_sector[Constants::Col_max_S]
      new_hsl[Constants::HSL_S]=new_sector[Constants::Col_min_S]-((new_sector[Constants::Col_max_S]-new_sector[Constants::Col_min_S]).abs/30.0)*current_position
    else
      new_hsl[Constants::HSL_S]=new_sector[Constants::Col_min_S]+((new_sector[Constants::Col_max_S]-new_sector[Constants::Col_min_S]).abs/30.0)*current_position
    end
    #Lightness
    if new_sector[Constants::Col_min_L]>new_sector[Constants::Col_max_L]
      new_hsl[Constants::HSL_L]=new_sector[Constants::Col_min_L]-((new_sector[Constants::Col_max_L]-new_sector[Constants::Col_min_L]).abs/30.0)*current_position
    else
      new_hsl[Constants::HSL_L]=new_sector[Constants::Col_min_L]+((new_sector[Constants::Col_max_L]-new_sector[Constants::Col_min_L]).abs/30.0)*current_position             
    end
    
    new_hsl[Constants::HSL_S]*=saturation_difference
    new_hsl[Constants::HSL_L]*=lightness_difference
    
    new_hsl[Constants::HSL_S]= new_hsl[Constants::HSL_S]>100 ? 100 : new_hsl[Constants::HSL_S]
    new_hsl[Constants::HSL_L]= new_hsl[Constants::HSL_L]>100 ? 100 : new_hsl[Constants::HSL_L]
    
    new_rgb = hsl_to_rgb(new_hsl)
    
    return Colour.new(new_rgb[0],new_rgb[1],new_rgb[2])
    
  end
  
  #Given a hue, it returns the 
  #information about that sector
  def get_sector_info_by_hsl(hue)  
    #[number, min_hue, max_hue, min_saturation, max_saturation, min_brightness, max_brightness]
    case hue
    when 0 .. 27
      [0,0,27,100,100,50,50] 
    when 28 .. 40
      [1,28,40,100,100,50,50]
    when 41 .. 49
      [2,41,49,100,100,50,50]
    when 50 .. 60  
      [3,50,60,100,100,50,50]
    when 61 .. 80
      [4,61,80,100,100,50,46]
    when 81 .. 120
      [5,81,120,100,100,47,39]
    when 121 .. 180
      [6,121,180,100,100,39,30]
    when 181 .. 221
      [7,181,221,100,80,30,37]
    when 222 .. 254
      [8,222,254,80,80,37,38]
    when 255 .. 278
      [9,255,278,79,89,38,35]
    when 278 .. 326
      [10,278,326,100,100,35,40]
    when 327 .. 359
      [11,327,359,100,100,40,49]
    end
  end
  
  #Given a sector number, it returns the 
  #information about that sector
  def get_sector_info_by_sector(sector)  
    case sector
    when 0
      [0,0,27,100,100,50,50]
    when 1
      [1,28,40,100,100,50,50]
    when 2
      [2,41,49,100,100,50,50]
    when 3  
      [3,50,60,100,100,50,50]
    when 4
      [4,61,80,100,100,50,46]
    when 5
      [5,81,120,100,100,47,39]
    when 6
      [6,121,180,100,100,39,30]
    when 7
      [7,181,221,100,80,30,37]
    when 8
      [8,222,254,80,80,37,38]
    when 9
      [9,255,278,79,89,38,35]
    when 10
      [10,278,326,100,100,35,40]
    when 11
      [11,327,359,100,100,40,49]
    end
  end
end



