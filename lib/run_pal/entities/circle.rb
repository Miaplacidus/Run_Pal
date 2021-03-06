module RunPal
  class Circle < Entity
    attr_accessor :id, :name, :admin_id, :member_ids, :max_members, :latitude, :longitude, :description, :level
    # member_ids: array -> CircleUsers table
    validates_presence_of :name, :admin_id, :max_members, :latitude, :longitude, :description, :level

    def initialize(attrs={})
      @member_ids = []
      super
    end
  end
end
