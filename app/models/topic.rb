class Topic < ActiveRecord::Base
  validates :comment, presence:true, length: {maximum: 140}

  belongs_to :user
  # CommentモデルのAssociationを設定
  has_many :comments, dependent: :destroy

  mount_uploader :photo, PhotoUploader
end
