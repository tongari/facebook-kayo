class TopicController < ApplicationController

  before_action :set_topic, only:[ :edit, :update, :destroy]

  def index
    @topics = Topic.all;
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

end
