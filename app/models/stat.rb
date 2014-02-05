class Stat
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, type: String
  field :value, type: String
  field :valuetwo, type: String

  index({ type: 1 })
end