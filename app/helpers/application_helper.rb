module ApplicationHelper
  module ApplicationHelper
    # 省略
    def profile_img(user)
      unless user.provider.blank?
        img_url = user.image_url
      else
        img_url = 'def_profile.svg'
      end
      image_tag(img_url, alt: user.name)
    end
    # 省略
  end
end
