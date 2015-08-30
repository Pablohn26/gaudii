module CollectHelper
  def add_text_link(name)
    link_to_function name do |page|
			page.insert_html :bottom, 'elements', :partial => 'text'
			page.visual_effect :highlight, :new_group, :duration => 0.3, :startcolor => '#34d85e'
		end
  end
  
  def add_group_link (name)
    link_to_function(name, nil) do |page|
      page.insert_html :bottom, 'groups', :partial => 'group'
      page.visual_effect :highlight, :group, :duration => 0.3, :startcolor => '#34d85e'
    end
  end
	
	
	
end


