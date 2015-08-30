#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

class Genes < Array
  
  attr_accessor :init_questions, :gen_family
  
  def initialize()
    super()
  end
  
  def start_creation(init_questions, shape)
    @init_questions = init_questions
    generation(shape)
  end
  
  def start_mix(init_questions, gen_family)
    @init_questions = init_questions
    @gen_family = gen_family
    mix
  end
  
  def mix
    rand = Kernel.rand(2)
    child_one = @gen_family[rand][Kernel.rand(@gen_family[rand].length)]
    child_two = @gen_family[rand][Kernel.rand(@gen_family[rand].length)]
    20.times do |n|
      rand = Kernel.rand(2)
      child_one = child_one.crossover(@gen_family[rand][Kernel.rand(@gen_family[rand].length)])
      rand = Kernel.rand(2)
      child_two = child_two.crossover(@gen_family[rand][Kernel.rand(@gen_family[rand].length)])
    end
    
    final_child = child_one.crossover(child_two)
    final_child.init_questions = @init_questions
    final_child.check_consistency("don't_check")
    
    return final_child
  end
  
  def generation(shape)
    #Random generation
    32.times do |n|
      self[n] = Kernel.rand(9)
    end
    
    check_consistency(shape)
  end
    
  def check_consistency(shape)
    #Image Shape
    ##################
    if shape=='curved'
      self[Constants::G_Image_Shape] = 0
    elsif shape=='slightly curved'
      self[Constants::G_Image_Shape] = 4
    elsif shape=='slightly straight'
      self[Constants::G_Image_Shape] = 6
    elsif shape=='straight'
      self[Constants::G_Image_Shape] = 8
    end
    
    #Initial questions
    ################## 
    #Source of color
    if init_questions['q2'] == '2'
      self[Constants::G_Color_source]=Kernel.rand(7)
    elsif init_questions['q2'] == '3'
      self[Constants::G_Color_source]=8
    end
    
    #Use of color
    if init_questions['q3'] == '2'
      self[Constants::G_Use_of_colors]=0
    elsif init_questions['q3'] == '3'
      self[Constants::G_Use_of_colors]=5
    elsif init_questions['q3'] == '4'
      self[Constants::G_Use_of_colors]=9
    end
    
    #Darkness
    if init_questions['q4'] == '2'
      self[Constants::G_Darkness]=8
    elsif init_questions['q4'] == '3'
      self[Constants::G_Darkness]=1
    end
    
    #Fonts
    if init_questions['q5'] == '2'
      self[Constants::G_Primary_font_style]=Kernel.rand(7)
    elsif init_questions['q5'] == '3'
      self[Constants::G_Primary_font_style]=9
    end
    
    #Horizontal/Vertical
    if init_questions['q6'] == '2'
      self[Constants::G_Orientation]=1
    elsif init_questions['q6'] == '3'
      self[Constants::G_Orientation]=8
    end
    
    #################
    #End of initial questions
    
    #Size
    if self[Constants::G_Contrast_Size]>=7
      self[Constants::G_Repetition_Size] = Kernel.rand(4)
    end
   
    #Shape
    if self[Constants::G_Contrast_Shape]>=4.5
      self[Constants::G_Repetition_Shape] = Kernel.rand(4)
    else
      self[Constants::G_Repetition_Shape] = Kernel.rand(4)+5
    end
    
    #Font style
    if self[Constants::G_Contrast_Font_style]>=4.5
      self[Constants::G_Repetition_Font_style] = Kernel.rand(4)
    elsif self[Constants::G_Repetition_Font_style] >=4.5
      self[Constants::G_Contrast_Font_style] = Kernel.rand(4)
    elsif self[Constants::G_Contrast_Font_style]<4.5
      self[Constants::G_Repetition_Font_style] = Kernel.rand(4)+5
    elsif self[Constants::G_Repetition_Font_style]<4.5
      self[Constants::G_Contrast_Font_style] = Kernel.rand(4)+5
    end
    
    #Colors
    if self[Constants::G_Contrast_Colors]>=4.5
      self[Constants::G_Repetition_Colors] = Kernel.rand(4)
    elsif self[Constants::G_Repetition_Colors] >=4.5
      self[Constants::G_Contrast_Colors] = Kernel.rand(4)
    elsif self[Constants::G_Contrast_Colors]<4.5
      self[Constants::G_Repetition_Colors] = Kernel.rand(4)+5
    elsif self[Constants::G_Contrast_Colors]<4.5
      self[Constants::G_Repetition_Colors] = Kernel.rand(4)+5
    end
    
    #Colors (random --> no picture as bg)
    if self[Constants::G_Color_source]>=7
      self[Constants::G_Image_BG] = Kernel.rand(4)+5
    end

  end
  
  def mod_entries_bits(img_width, img_height)    
    #ENTRIES BITS
    if (img_width.to_f/img_height.to_f)>1.2
      self[1] = 8 #Too horizontal
    elsif (img_height.to_f/img_width.to_f)>1.2
      self[1] = 1 #Too vertical
      self[0] =Kernel.rand(4)+5
    end
    
  end
  
  def crossover(pair)
    crossover=Genes.new()
    pair.length.times do |n|
      crossing_random= Kernel.rand(101)
      if crossing_random<=1 #Some random magic
        crossover[n]=Kernel.rand(9)
      elsif crossing_random>1 and crossing_random<51 #Mom
        crossover[n]=self[n]
      else #Dad
        crossover[n]=pair[n]
      end
    end
    
    return crossover
  end

  
end