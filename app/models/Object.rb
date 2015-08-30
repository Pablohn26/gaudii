#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

class Object
  #Marshaling is like serialization in Java. This is for
  #deep cloning of object, but it's very slow.
  def deep_clone
    Marshal::load(Marshal::dump(self))
  end
  
  #Since the deep clone is to slow, we use this 
  #just for cloning groups 
  def groups_deep_clone
    clone_group = Array.new
    
    self.length.times do |n|
      clone_group << self[n].clone
      
      clone_group[n].items = Array.new
      self[n].items.each do |i|
        clone_group[n].items << i.clone
      end
    end
    
    return clone_group
  end
end