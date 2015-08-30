#############################################
# Víctor José Martín Ramírez                #
# Carlos González Morcillo                  #
# Código bajo licencia GPL 3                #
# => http://www.gnu.org/licenses/gpl.html   #
#############################################

# Fuzzy Inference Engine

require 'rexml/document'
include REXML

#This may be an antecedent or a consequent, since they
#act the same in the end.
class Rule_element
  attr_accessor :lv_name, :tag, :bit_position, :membership_d, :height
  
  def initialize(lv_name, tag, bit_position)
    @lv_name = lv_name
    @tag = tag
    @bit_position = bit_position.to_i
    @membership_d = 0.0
  end 
  
end

#Any rule has a name, a numbers of antecedents/consequents and a area/centroid array.
class Rule
  attr_accessor :name, :antecedents, :consequents, :ant_value, :area_centroid
  
  def initialize(name)
    @name=name
    @antecedents=[]
    @consequents=[]
    @ant_value = 1.0
  end
  
  def add_antecedent(antecedent)
    @antecedents << antecedent
  end
  
  def add_consequent(consequent)
    @consequents << consequent
  end
  
end

#Any Fuzzy Set will have four points and a name.
class Fuzzy_set
  attr_reader :name, :a, :b, :c, :d
  
  def initialize(name, a, b, c ,d)
    @name= name
    @a = a.to_f
    @b = b.to_f
    @c = c.to_f
    @d = d.to_f
  end
  
end

#Each linguistic variable is an array of fuzzy sets 
#with its type and a fixed tag that will represent it.
class Linguistic_variable
  attr_reader :tag, :type, :fuzzy_sets
  
  def initialize(tag, type)
    @tag = tag
    @type = type
    @fuzzy_sets = {}
  end
  
  def add_fuzzy_set(name, fuzzy_set)
    fuzzy_sets[name] = fuzzy_set
  end
  
end

#A System is a group of rules and linguistic variables that is
#represented with a name 
class System
  attr_accessor :lv_hash, :rules_hash, :name, :conclusion, :bit_position
  
  def initialize(name)
    @name = name
    @lv_hash = {}
    @rules_hash = {}
  end
  
end

class Fie
  attr_accessor :rules, :design, :doc, :systems
  
  def initialize()
    
  end

  #Executes all the process
  def run_fie(design, rules_filename="public/xml/rules.xml")
    @design=design
    @systems = {}
    open_xml(rules_filename)
    start_engine
    fuzzyfication 
    rule_evaluation
    defuzzification
  end

  #It opens an XML file passed by argument. "rules.xml" will be
  #loaded by default if there is n oargument.
  def open_xml(rules_filename)
    @doc = Document.new(File.new(rules_filename))
  end
  
  #This function reads the XML and add the data to the
  #data structure of the FIE.
  def start_engine
    root=doc.root
    #Systems checking
    root.elements.each do |system|#For each System do...
      system_name=system.attributes["name"]
      systems[system_name]=System.new(system_name)
      #Linguistic variables and Rules checking
      system.elements.each do |lvr| #For each rule or linguistic variable do...
        if lvr.name=='linguisticvariable' #It is a linguistic variable
          lv_name=lvr.attributes["name"]
          systems[system_name].lv_hash[lv_name]=Linguistic_variable.new(lv_name, lvr.attributes["type"])
          #Fuzzy Sets checking
          lvr.elements.each do |fs|#For each Fuzzy Set do...
            systems[system_name].lv_hash[lv_name].add_fuzzy_set(fs.attributes["tag"], Fuzzy_set.new(fs.attributes["tag"], fs.attributes["a"], fs.attributes["b"], fs.attributes["c"], fs.attributes["d"]))
          end
        else#It is a rule
          rule_name=lvr.attributes["name"]
          systems[system_name].rules_hash[rule_name] = Rule.new(rule_name)
          #Antecedents and Consequents checking
          lvr.elements.each do |anco|#For each antecedent or consequent do...
            if anco.name=='antecedent' #It is an antecedent
              systems[system_name].rules_hash[rule_name].add_antecedent(Rule_element.new(anco.attributes["varname"],anco.attributes["tag"], anco.attributes["bit_position"]))
            else #It is a consequent
               systems[system_name].rules_hash[rule_name].add_consequent(Rule_element.new(anco.attributes["varname"],anco.attributes["tag"], anco.attributes["bit_position"]))
               systems[system_name].bit_position=anco.attributes["bit_position"].to_i
            end
          end #if antecedent/consequent
        end #if linguisticvariables/rules
      end #each Linguistic Variables and rules
    end #each Systems
  end#def Start_engine
  
  #This function checks every antecedent in every
  #rule and calculate its membership degree by
  #calling that function.
  def fuzzyfication
    systems.each do |key_s,s|#for each System
      s.rules_hash.each do |key_r,r|#for each Rule
        r.antecedents.each do |a|#for each Antecedent
          a.membership_d=calculate_membership_degree(s,a)
        end #each antecedents
      end #each rules
    end #each systems
  end #def fuzzyfication
  
  #Given a system and an antecedent, this calculates its
  #membership degree
  def calculate_membership_degree(system,antecedent)
    a = system.lv_hash[antecedent.lv_name].fuzzy_sets[antecedent.tag].a
    b = system.lv_hash[antecedent.lv_name].fuzzy_sets[antecedent.tag].b
    c = system.lv_hash[antecedent.lv_name].fuzzy_sets[antecedent.tag].c
    d = system.lv_hash[antecedent.lv_name].fuzzy_sets[antecedent.tag].d
    x= design.gen_bits[antecedent.bit_position]
    
    if x>=a and x<b#between a and b
      if x == a 
        0 
      else
        (x-a)/(b-a)
      end
    elsif x>=b and x<=c#between b and c
      1
    elsif x>c and x<=d #between c and d
      if x == d 
        0 
      else
        (d-x)/(d-c)
      end
    else#out of the function
      0
    end#if point checking
    
  end#def calculate_membership_degree
  
  #Given a system, a consequent and the maximum hegith 
  #obtained from the antecedents, this calculates the area 
  #and the centroid for each consequent.
  def calculate_area_centroid(system, consequent, height)
    fuzzy_set = systems[system.name].lv_hash[consequent.lv_name].fuzzy_sets[consequent.tag]
    
    a= fuzzy_set.a
    
    if fuzzy_set.a==fuzzy_set.b
      b=fuzzy_set.b
    else 
      b= height*(fuzzy_set.b - a) + a
    end
    
    d= fuzzy_set.d
    
    if fuzzy_set.c==fuzzy_set.d
      c=fuzzy_set.c
    else
      c= d - height*(fuzzy_set.d - fuzzy_set.c)
    end
    
    big_base = d - a
    small_base = big_base -((b-a)+(d-c))

    #Trapezoid area= height*(big base + small base)/2
    area= height*(big_base+small_base)/2
    centroid = a + (d-a)/2
    
    return [area, centroid]
    
  end#def calculate_area_centroid
  
  #This evaluates the antecedents in every rule and
  #gets the minimun value. After that, it calculates the
  #area and centroid for every rule by calling 
  #the calculate_area_centroid fuction
  def rule_evaluation
    systems.each do |key_s, s|#Systems
      s.rules_hash.each do |key_r, r|#Rules
        r.antecedents.each do |a| #Antecedents
          r.ant_value = [r.ant_value, a.membership_d].min #Having minimun value between all the antecedents for that rule
        end#each Antecedents
        r.consequents.each do |c| #Consequents
          r.area_centroid = calculate_area_centroid(s, c, r.ant_value)
        end#each Consequents
      end#each Rules
    end#each Systems
  end#def rule_evaluation
  
  #Given all the areas for each consequents in the system's rules,
  #it calculates the final consequents. 
  def defuzzification
    products_sum=0
    areas_sum=0
    systems.each do |key_s, s|#Systems
      s.rules_hash.each do |key_r, r|#Rules
        products_sum += r.area_centroid[0]*r.area_centroid[1] #Area * Centroid
        areas_sum += r.area_centroid[0] #Area
      end#each Rules
      s.conclusion=products_sum/areas_sum
      products_sum=0
      areas_sum=0
      design.values_bits[systems[s.name].bit_position]=s.conclusion #We store the result in an array in the Design object
    end#each Systems
  end#def defuzzification
  
end #Fie class

