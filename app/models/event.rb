class Event < ActiveRecord::Base
  before_save :schedule_to_yaml

  validates_presence_of :name

  # Geocoding
  geocoded_by :address
  after_validation :geocode

  def self.find_in_range(start_date, end_date)
    events = []
    Event.all.each do |event|
      events << event if event.schedule.occurrences_between(start_date, end_date).size > 0
    end
    events
  end

  def self.get_ordered_events(start_date, end_date)
    events = []
    Event.find_in_range(start_date, end_date).each do |event|
      event.schedule.occurrences_between(start_date, end_date).each do |time|
        time = time.beginning_of_day if event.full_day
        events << {time: time, event:event}
      end
    end

    events.sort_by {|el| [el[:time], el[:event].name]}
  end

  def address
    [self.street, "#{self.zipcode} #{self.city}"].delete_if {|d| d.blank?}.collect{|d|d.strip}.join(", ")
  end

  def schedule
    if @schedule.nil?
      if !self.schedule_yaml.blank?
        begin
          @schedule = IceCube::Schedule.from_yaml(self.schedule_yaml)
        rescue => e
          # Shit, parsing went wrong
        end
      end

      if @schedule.nil?
        @schedule = IceCube::Schedule.new(Time.now, :duration => 60 * 60)
      end
    end
    @schedule
  end

  def schedule=(cube_obj)
    @schedule = cube_obj
  end

  def to_param
    "#{self.id}-#{self.name.parameterize}"
  end
  
  private

  def schedule_to_yaml
    self.schedule_yaml = @schedule.to_yaml if !@schedule.nil?
  end

end
