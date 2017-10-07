module TopicHelper
  def choose_new_or_edit
    if action_name == 'new' || action_name == 'create'
      topic_index_path
    elsif action_name == 'edit' || action_name == 'update'
      topic_path
    end
  end
end
