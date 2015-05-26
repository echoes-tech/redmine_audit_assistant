class ProgressReport
  
  attr_reader :root, :date_from, :date_to, :occupation_persons
  
  def initialize(root, date_from, date_to, occupation_persons=nil)
    @root = root
    @date_from = date_from
    @date_to = date_to
    @occupation_persons = format_occupation_persons_map(occupation_persons)
    if !@date_from
      @date_from = date_beginning
    end
    if !@date_to
      to_end_of_week
    end
  end
  
  def to_end_of_week
    @date_to = Chronic.parse('next friday', :now => @date_from)
  end
  
  @@nb_hours_per_day = 8
  
  include ProgressReportHelper
  
  # abstract method
  def issues
    raise NotImplementedError
  end
  
  def date_beginning
    issues.map {|issue| issue.created_on }.min
  end
  
  def date_effective
    issues.map { |issue| issue.due_date }.max
  end
  
  def date_estimated
    
    days_left = charge_left 'd'
    
    current = @date_to
    
    while days_left > 0 do
      current = current + 1.days
      if !current.saturday? && !current.sunday?
        days_left -= 1
      end
    end
    
    current
    
  end
  
  # return the list of issues that has been updated during a given period
  def issues_updated
    
    issues_list = issues
    
    journals = get_issues_journals(issues_list, @date_from, @date_to)
    
    issues_ids_changed = journals.map { |j| j.journalized_id }
    
    issues_list.select { |issue| issues_ids_changed.include?(issue.id) }
    
  end
  
  # total estimated_hours of every issue
  def charge_effective(format='h')
    
     total = issues.map { |issue| issue.estimated_hours ? issue.estimated_hours : 0 }.reduce(:+) 
     
     format_hours(total, format)
     
  end
  
  # total estimated hours of every issue 
  # with taking into consideration the % occupation per person
  def charge_estimated(format='h')
    
    total = 0
    issues.each do |issue|
      if issue.estimated_hours
        tx = 1
        if @occupation_persons[issue.assigned_to_id]
          tx = @occupation_persons[issue.assigned_to_id] / 100.00
        end
        total += issue.estimated_hours / tx
      end
    end
    
    format_hours(total, format)
    
  end
  
  # total charge left at the end of period
  def charge_left(format='h')
    
    total = 0
    issues.each do |issue|
      if issue.estimated_hours && !issue.status.is_closed?
        tx = 1
        if @occupation_persons[issue.assigned_to_id]
          tx = @occupation_persons[issue.assigned_to_id] / 100.00        
        end
        done_ratio = issue.done_ratio ? issue.done_ratio : 0
        todo_ratio = 1 - (done_ratio / 100.00)
        total += todo_ratio * issue.estimated_hours / tx
      end
    end
    
    format_hours(total, format)
    
  end
  
  def get_week_periods
    
    date_beggining_project = date_beginning
    periods = Array.new
    
    date_from = Chronic.parse('monday', :context => :past)
    date_to = Chronic.parse('friday', :now => date_from)
    
    if date_beggining_project.nil?
      date_beggining_project = @date_from
    end
    
    while date_to >= date_beggining_project do
          
      periods.push([date_from, date_to])
      
      date_from = Chronic.parse('last monday', :now => date_from)
      date_to = Chronic.parse('last friday', :now => date_to)
      
    end
    
    periods   
  end
  
  private # ----------------------------------------------------------------
  
  def format_occupation_persons_map(occupation_persons)
    if occupation_persons
      return Hash[occupation_persons.keys.map(&:to_i).zip(occupation_persons.values.map(&:to_i))]
    else
      return Hash.new
    end
  end
  
  def format_hours(hours, format)   
    if format == 'd'
       hours = hours / @@nb_hours_per_day
       hours = hours.ceil
    end
    hours   
  end
  
end