module CommentsHelper
  def isAsync
    if  action_name == 'create'
      true
    elsif action_name == 'update'
      false
    end
  end
end
