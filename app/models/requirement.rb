class Requirement < ActiveRecord::Base
  
  belongs_to :requirement
  has_many :children, :class_name => 'Requirement', foreign_key: "requirement_id"
  
  attr_accessor :issue
  
  serialize :checklist
  
  include RequirementToIssueHelper
  
  @issue = nil
  
  def assignee
    User.find_by_login(self.assignee_login)
  end
  
  def priority
    IssuePriority.find_by_position(self.priority_id)
  end
  
end
