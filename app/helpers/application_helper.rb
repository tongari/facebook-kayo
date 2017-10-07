module ApplicationHelper
  def profile_img(user)
    return image_tag(user.avatar, alt: user.name, class: 'user-thumb') if user.avatar?

    unless user.provider.blank?
      img_url = user.image_url
    else
      img_url = 'def_profile.svg'
    end
    image_tag(img_url, alt: user.name, class: 'user-thumb')
  end
end
