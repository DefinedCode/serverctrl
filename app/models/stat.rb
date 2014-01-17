class Stat
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, type: String
  field :value, type: String

  index({ type: 1 })
end