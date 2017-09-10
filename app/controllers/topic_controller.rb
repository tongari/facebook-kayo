class TopicController < ApplicationController

  before_action :set_topic, only:[ :edit, :update, :destroy]
  before_action :checkMatchUser, only:[:edit, :destroy]
  before_action :isLogin, only:[:index, :new, :edit]

  def index
    @topics = Topic.all;
    @curUserId = current_user.id
    @users = User.all
  end

  def new
    if request.post?
      @topic = Topic.new(topic_params)
    else
      @topic = Topic.new
    end
  end

  def create
    @topic = Topic.new(topic_params)
    @topic.user_id = current_user.id
    if @topic.save
      redirect_to topic_index_path, notice: '投稿しました！'
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @topic.update(topic_params)
      redirect_to topic_index_path, notice: '更新しました！'
    else
      render 'edit'
    end
  end

  def destroy
    @topic.destroy
    redirect_to topic_index_path, notice: '削除しました！'
  end

  private
    def topic_params
      params.require(:topic).permit(:photo, :photo_cache, :comment)
    end

    def set_topic
      @topic = Topic.find(params[:id])
    end

    def checkMatchUser
      if current_user.id != @topic.user_id
        redirect_to topic_index_path
      end
    end

    def isLogin
      if !user_signed_in?
        redirect_to new_user_session_path
      end
    end

end
