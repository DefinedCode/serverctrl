class Setup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :data, type: String

  index({ name: 1 })
end
