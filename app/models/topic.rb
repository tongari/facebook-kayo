class Topic < ActiveRecord::Base
  validates :comment, presence:true, length: {maximum: 140}
  validates :photo, presence: true

  mount_uploader :photo, PhotoUploader
end
