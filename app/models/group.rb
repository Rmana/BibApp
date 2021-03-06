class Group < ActiveRecord::Base
  acts_as_tree :order => "name"
  acts_as_authorizable  #some actions on groups require authorization
  
  #### Associations ####
  
  has_many :people,
    :through => :memberships,
    :order => "last_name, first_name"
  has_many :memberships

  #### Callbacks ####
  
  #Note: 'after_save' callback is located in 'group_observer.rb', to make
  # sure it is called *before* after_save in 'index_observer.rb'
  # (That way Group info is updated completely *before* re-indexing of works)
 
  #### Methods ####
  
  def save_without_callbacks
    update_without_callbacks
  end
  
  
  def works
    # @TODO: Do this the Rails way.
    self.people.collect{|p| p.works.verified}.uniq.flatten
  end

  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end 

  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{name}||#{id}"
  end 
  
  def solr_filter
    'group_id:"' + self.id.to_s + '"'
  end

  #Update Machine Name of Group (called by after_save callback)
  def update_machine_name
    #Machine name only needs updating if there was a name change
    if self.name_changed?
      #Machine name is Group Name with:
      #  1. all punctuation/spaces converted to single space
      #  2. stripped of leading/trailing spaces and downcased
      self.machine_name = self.name.mb_chars.gsub(/[\W]+/, " ").strip.downcase
      self.save_without_callbacks
    end
  end

  #Return the group's top-level parent (ancestor)
  def top_level_parent
    if self.parent.nil?
      return self
    else
      return self.parent.top_level_parent
    end
  end

  def ancestors_and_descendants
    family = Array.new
    family << self.ancestors
    family << self.descendants
  end

  def descendants
    self.children.map(&:descendants).flatten + self.children
  end
  
  class << self
    # return the first letter of each name, ordered alphabetically
    def letters
      find(
        :all,
        :select => 'DISTINCT SUBSTR(name, 1, 1) AS letter',
        :order  => 'letter',
        :conditions => ["hide = ?", false]
      )
    end
    
    #Parse Solr data (produced by to_solr_data)
    # return Group name and ID
    def parse_solr_data(group_data)
      data = group_data.split("||")
      name = data[0]
      id = data[1]  
      
      return name, id
    end
  end
end