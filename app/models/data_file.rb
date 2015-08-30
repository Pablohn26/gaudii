#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

#This class is used for uloading files
#such as images or XML.
class DataFile < ActiveRecord::Base
  def self.save(upload, path)
    path += upload['datafile'].original_filename
    # write the file
    File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
  end
  
  
  
end
