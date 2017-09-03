class Topic < ActiveRecord::Base
  validates :comment, presence:true, length: {maximum: 140}

  mount_uploader :photo, PhotoUploader
end
