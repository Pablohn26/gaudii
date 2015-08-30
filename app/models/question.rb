#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

#This object is utilized for
#creating the preferences questions
#from the XML file
class Question
  attr_accessor :options, :answer, :question, :number
  
  def initialize(number, content)
    @options = {}
    @number = number.to_i
    @question = content.to_s
  end
  
  def add_option(string, value)
    @options[string] = value
  end
  
end