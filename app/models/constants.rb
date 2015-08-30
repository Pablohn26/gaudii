#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

#Constants storing class
class Constants
  Big_step = 2
  Medium_step = 4
  Small_step = 6
  
  Grow_factor = 1.15
  Shrink_factor = 1.10
  
  Min_allowed_factor = 0.65
  Shrink_font_factor_big = 0.70
  Shrink_font_factor_small = 0.80

  Main_image = 0
  Text_image = 1
  Logo_image = 2

  Big_num = 10000
  
  Margin_text_pics = 10
  Min_text_image_size = 60
  
  #Genetic bits numbers
  G_Design_shape = 0
  G_Orientation = 1
  G_Primary_font_style = 3
  G_Contrast_Size = 4
  G_Contrast_Colors = 5
  G_Contrast_Shape = 6
  G_Contrast_Font_style = 11
  G_Repetition_Size = 12
  G_Repetition_Colors = 13
  G_Repetition_Shape = 14
  G_Repetition_Font_style = 18
  G_Image_Shape = 20
  G_Use_of_colors = 21
  G_Color_source = 22
  G_Image_BG = 23
  G_Darkness = 24
  
  #Values bits numbers
  V_Design_ratio = 0
  V_Design_orientation = 1
  V_Primary_font_style = 3
  V_Size_h0 = 4
  V_Size_h1 = 5
  V_Size_h2 = 6
  V_Size_h3 = 7
  V_Size_h4 = 8
  V_Main_color = 9
  V_Predominant_shape = 10
  V_Texts_BG = 12
  V_Weight_h0 = 14
  V_Weight_h1 = 15
  V_Weight_h2 = 16
  V_Weight_h3 = 17
  V_Weight_h4 = 18
  V_Secondary_font_style = 19
  V_Use_of_colors = 21
  V_Type_of_BG = 22
  V_Accent_colors = 23
  V_BG_color = 24
  V_Darkness = 25
  V_Margins = 26
  V_Image_position = 27
  V_All_caps = 28
  V_Zooming = 29
  V_type_of_BG_decoration = 30
  
  #Results
  Low_Value = 1.5
  Medium_Value = 4.5
  High_Value = 
  
  #Others
  Min_lightness = 60
  
  #Colors
  Col_number = 0
  Col_min_H = 1
  Col_max_H = 2
  Col_min_S = 3
  Col_max_S = 4
  Col_min_L = 5
  Col_max_L = 6
  
  HSL_H = 0
  HSL_S = 1
  HSL_L = 2
  
  #Compositor 
  Zeros = 7
  
end