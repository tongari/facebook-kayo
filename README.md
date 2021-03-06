# rails環境構築

### 参考url
[http://qiita.com/emadurandal/items/e43c4896be1df60caef0](http://qiita.com/emadurandal/items/e43c4896be1df60caef0)


- 事前準備
```bash
$ rbenv local 2.3.0
$ ndenv local v6.10.2
$ rbenv exec gem install bundler
```

- プロジェクトのフォルダのみにGemをインストールする

```bash
$ echo "source 'http://rubygems.org'" >> Gemfile
$ echo "gem 'rails', '4.2.3'" >> Gemfile
$ bundle install --path vendor/bundle
```
`※ nokogiriが結構インストールするのに時間かかる`


- railsプロジェクトを作成（turbolinksは最初から無効）
```bash
$ rails new ./ -d postgresql --skip-bundle --skip-turbolinks
$ bundle install --path vendor/bundle
$ rake db:create
```
`※ 事前にエイリアスで「bundle exec rails　-> rails」と「bundle exec rake　-> rake」は張り替えている`


- gitの管理対象から以下を外す
```bash
$ echo '/vendor/bundle' >> .gitignore
$ echo '.env' >> .gitignore
$ echo '.idea/' >> .gitignore
```

# ログイン機能を作成

- deviseをインストールする
```bash
$ echo "gem 'devise'" >> Gemfile
$ bundle install --path vendor/bundle
```

- deviseに必要な初期設定とそのファイルを生成
```bash
$ rails generate devise:install
```

- Userモデルを作成する
```bash
$ rails g devise user
$ rake db:migrate
```

- Viewを作成する
```bash
$ rails generate devise:views
```


# Deviseのエラーメッセージを日本語化する

- デフォルトの設定を日本語にする

`config/application.rb`に以下を記載
```ruby
config.i18n.default_locale = :ja
```

- 日本語の辞書ファイルを作成する

`config/locales/devise.ja.yml`を作成
`config/locales/devise.ja.yml`に日本語に翻訳された辞書をセット

[参考辞書リストはこちら](https://gist.github.com/kaorumori/7276cec9c2d15940a3d93c6fcfab19f3)


# バリデーションエラーメッセージの日本語化

`config/locales/ja.yml`を作成

[参考辞書リストはこちら](https://github.com/svenfuchs/rails-i18n/blob/master/rails/locale/ja.yml)



# ユーザ新規登録した際に認証メールが送信されるようにする

- ローカル開発確認用にletter_opener_webをインストールする
`Gemfile`
```ruby
group :development do
  gem 'letter_opener_web'
end
```

- letter_opener_webのroutingを設定する

`config/routes.rb`
```ruby
if Rails.env.development?
  mount LetterOpenerWeb::Engine, at: '/letter_opener'
end
```
- 開発環境でメール送信の際、letter_opener_webを使用するように設定する

`config/environments/development.rb`
```ruby
config.action_mailer.default_url_options = { host: 'localhost:3000' }
config.action_mailer.delivery_method = :letter_opener_web
```

- Userモデルに`:confirmable`を追加

`app/models/user.rb`
```ruby
devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable
```

- メール認証に必要なカラムを追加

```bash
$ rails g migration add_confirmable_to_devise
```

- 上記コマンドで生成されたマイグレーションファイルを書き換える

```ruby
class AddConfirmableToDevise < ActiveRecord::Migration
  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index :users, :confirmation_token, unique: true
    # User.reset_column_information # Need for some types of updates, but not for update_all.

    execute("UPDATE users SET confirmed_at = NOW()")
  end

  def down
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
    remove_columns :users, :unconfirmed_email # Only if using reconfirmable
  end
end
```

migration fileを編集後`rake db:migrate`を実行
もし、すでにユーザを新規登録していた場合はRailsコンソールを立ち上げて`User.delete_all`で全部削除


# トピック機能を作成

- controller作成
```bash
$ rails g controller topic index
```

- model作成
```bash
$ rails g model topic photo:string comment:text
```

## 画像アップローダーとしてcarrierwaveとmini_magickをインストールする

- homebrewにimagemagickをインストールする（すでに入っていれば必要ない）
```bash
$ brew update 
$ brew install imagemagick
```

- carrierwaveとmini_magickをインストールする
```bash
$ echo "gem 'carrierwave'" >> Gemfile
$ echo "gem 'mini_magick'" >> Gemfile
$ bundle install --path vendor/bundle
```

- carrierwaveの初期設定を行う。
```bash
$ rails generate uploader Photo
```

- models/topic.rbにcarrierwave用の設定を行う
```ruby
mount_uploader :photo, PhotoUploader
```

- 画像のリサイズ
`app/uploaders/photo_uploader.rb`に以下を記載
```ruby
include CarrierWave::MiniMagick
process resize_to_limit: [600, 600]
```

- 投稿するviewに以下を記載
`app/views/topic/_form.html.erb`
```
<%= f.file_field :photo %>
<%= f.hidden_field :photo_cache %><!-- バリデーションエラー時の対策 -->
```

- 一覧画面に投稿画像を表示
`app/views/topic/index.html.erb`
```
<% @topics.each do |topic| %>
  <%= image_tag(topic.photo, alt: '') %>
  <p><%= topic.comment %></p>
<% end %>
```

- 一連のCURD処理を作成

`〜省略〜`

- 画像アップロード時にプレビューできるようにjsを書く

`app/assets/javascripts/topic.js`
```javascript
var picUpLoadButton = document.querySelector('.js-picUpLoadButton');
var previewImg = document.querySelector('.js-previewPhoto');

picUpLoadButton && picUpLoadButton.addEventListener('change', function (e) {
  var file = e.target.files[0];
  var reader = new FileReader();

  reader.onload = (function(file) {
    return function(e) {
      previewImg.src = e.target.result;
    };
  })(file);
  reader.readAsDataURL(file);
});
```

`app/views/topic/_form.html.erb`
```
<div class="topic-preview">
  <%= image_tag(@topic.photo, alt: '', class: 'js-previewPhoto') %>
</div>
```


# アソシエーション

- Topicモデルに`user_id`カラムを追加
```bash
$ rails g migration AddUserIdToTopics user_id:integer
```

- UserモデルのレコードがTopicモデルのレコードを複数もつことを定義する

`app/models/user.rb`
```ruby
has_many :topics
```


# 自分の投稿にだけ、編集と削除をさせる

`app/views/topic/index.html.erb`
```
<% if topic.user_id == @curUserId %>
  <%= link_to edit_topic_path(topic.id) do %>
    <span class="glyphicon glyphicon-edit" aria-hidden="true"></span>
  <% end %>

  <%= link_to topic_path(topic.id), method: :delete ,data: { confirm: '本当に削除していいですか？' } do %>
      <span class="glyphicon glyphicon-trash" aria-hidden="true"></span>
  <% end %>
<% end %>
```

`app/controllers/topic_controller.rb`
```ruby
def checkMatchUser
  if current_user.id != @picture.user_id
    redirect_to picture_index_path
  end
end
```
など


# UserとTopicをひも付けて誰がTopicを投稿したか分かるようする

- Userモデルに名前用のカラムを追加
```bash
$ rails g migration AddNameToUsers name:string
$ rake db:migrate
```

- Deviseのストロングパラメータにnameを追加

`app/controllers/application_controller.rb`
以下を追加
```ruby
# before_actionで定義したメソッドを実行
before_action :configure_permitted_parameters, if: :devise_controller?

#変数PERMISSIBLE_ATTRIBUTESに配列[:name]を代入
PERMISSIBLE_ATTRIBUTES = %i(name)

protected
  #deviseのストロングパラメーターにカラム追加するメソッドを定義
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: PERMISSIBLE_ATTRIBUTES)
    devise_parameter_sanitizer.permit(:account_update, keys: PERMISSIBLE_ATTRIBUTES)
  end
```

- 新規ユーザ登録画面に名前の入力用のフィールドを追加

`app/views/devise/registrations/new.html.erb`
```
<div class="field">
  <%= f.email_field :email, autofocus: true, placeholder: "メールアドレス" %>
</div>

<!-- 名前入力用のフィールドを追加 -->
<div class="field">
  <%= f.text_field :name, placeholder: "名前" %>
</div>
```

- ユーザ編集画面に名前の入力用のフィールドを追加

`app/views/devise/registrations/edit.html.erb`
```
<div class="field">
  <%= f.label :メールアドレス %><br />
  <%= f.email_field :email, autofocus: true %>
</div>

<!-- 名前入力用のフィールドを追加 -->
<div class="field">
  <%= f.label :名前 %><br />
  <%= f.text_field :name %>
</div>
```

# SNSログインの実装

- omniauthをインストール

```bash
$ echo "gem 'omniauth'" >> Gemfile
$ echo "gem 'omniauth-twitter'" >> Gemfile
$ echo "gem 'omniauth-facebook'" >> Gemfile
$ bundle install --path vendor/bundle
```

- `:omniauthable`の定義を有効にする

`app/models/user.rb`
```ruby
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :omniauthable
# 省略
end
```

- ルーティング定義を追加

`/config/routes.rb`

```ruby
Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
end
```

- Facebookのアプリ登録

https://developers.facebook.com/

`開発環境用`と`本番用`２つ作成

```
本番環境（production)のみ、アプリレビューより ☓☓☓を公開しますか？をはいにする
```

- Twitterのアプリ登録

https://dev.twitter.com/ 

`開発環境用`と`本番用`２つ作成


- `config/initializers/devise.rb`に以下を追記

```ruby
Devise.setup do |config|
  if Rails.env.production?
    config.omniauth :facebook, ENV['FACEBOOK_ID_PROD'], ENV['FACEBOOK_SECRET_PROD'], scope: 'email', display: 'popup', info_fields: 'name, email'
    config.omniauth :twitter, ENV['TWITTER_ID_PROD'], ENV['TWITTER_SECRET_PROD'], scope: 'email', display: 'popup', info_fields: 'name, email'
  else
    config.omniauth :facebook, ENV['FACEBOOK_ID_DEV'], ENV['FACEBOOK_SECRET_DEV'], scope: 'email', display: 'popup', info_fields: 'name, email'
    config.omniauth :twitter, ENV['TWITTER_ID_DEV'], ENV['TWITTER_SECRET_DEV'], scope: 'email', display: 'popup', info_fields: 'name, email'
  end
end
```

### 開発環境用において、dotenvを使用して環境変数化を行う（※.envをgithubにあがらないように.gitignoreに必ず記載する！！！）

- dotenvをインストール

`Gemfile`
```ruby
group :development do
省略
  gem 'dotenv-rails'
end
```

```
$ bundle install --path vendor/bundle
```
- dotenvにIDとAppSecretを記述（開発環境用）

`.env`
```
FACEBOOK_ID_DEV={登録したアプリのID}
FACEBOOK_SECRET_DEV={登録したアプリのapp secret}
TWITTER_ID_DEV={登録したアプリのID}
TWITTER_SECRET_DEV={登録したアプリのapp secret}
```

- SNSログインで必要なカラムをUsersテーブルに追加する

```bash
$ rails g migration AddOmniauthColumnsToUsers uid provider image_url
```

```ruby
class AddOmniauthColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :uid, :string, null: false, default: ""
    add_column :users, :provider, :string, null: false, default: ""
    add_column :users, :image_url, :string

    add_index :users, [:uid, :provider], unique: true
  end
end
```

- マイグレーション

オプションで`null: false`を設定したので、`rake db:migrate`コマンドではなく`rake db:migrate:reset`コマンドを実行

- FacebookとTwitterのアクションを作成する

```bash
$ mkdir app/controllers/users
$ rails g controller users::OmniauthCallbacks
```

- OmniauthCallbacksControllerの継承元をApplicationControllerからDeviseのコールバックコントローラへ書き換える

`app/controllers/users/omniauth_callbacks_controller.rb`

```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
end
```

- Facebookログイン用のメソッドを作成する

`app/controllers/users/omniauth_callbacks_controller.rb`

```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      set_flash_message(:notice, :success, kind: "Facebook") if is_navigational_format?
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
end
```

- `find_for_facebook_oauth`/`find_for_twitter_oauth`メソッドをuser.rbに定義する

`app/models/user.rb`

```ruby
class User < ActiveRecord::Base
#省略
  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.find_by(provider: auth.provider, uid: auth.uid)

    unless user
      user = User.new(
          name:     auth.extra.raw_info.name,
          provider: auth.provider,
          uid:      auth.uid,
          email:    auth.info.email ||= "#{auth.uid}-#{auth.provider}@example.com",
          image_url:   auth.info.image,
          password: Devise.friendly_token[0, 20]
      )
      user.skip_confirmation!
      user.save(validate: false)
    end
    user
  end
end
```

`app/controllers/users/omniauth_callbacks_controller.rb`

```ruby
def twitter
  # You need to implement the method below in your model
  @user = User.find_for_twitter_oauth(request.env["omniauth.auth"], current_user)

  if @user.persisted?
    set_flash_message(:notice, :success, kind: "Twitter") if is_navigational_format?
    sign_in_and_redirect @user, event: :authentication
  else
    session["devise.twitter_data"] = request.env["omniauth.auth"].except("extra")
    redirect_to new_user_registration_url
  end
end
```

`app/models/user.rb`
```ruby
def self.find_for_twitter_oauth(auth, signed_in_resource = nil)
    user = User.find_by(provider: auth.provider, uid: auth.uid)

    unless user
      user = User.new(
          name:     auth.info.nickname,
          image_url: auth.info.image,
          provider: auth.provider,
          uid:      auth.uid,
          email:    auth.info.email ||= "#{auth.uid}-#{auth.provider}@example.com",
          password: Devise.friendly_token[0, 20]
      )
      user.skip_confirmation!
      user.save
    end
    user
  end
```


- users/registration_controllerを作成して、deviseのコントローラーを継承する

```bash
$ rails g controller users::registrations
```

`app/controllers/users/registration_controller`
```ruby
class Users::RegistrationsController < Devise::RegistrationsController
  def build_resource(hash=nil)
    hash[:uid] = User.create_unique_string
    super
  end
end
```

- create_unique_stringメソッドを作成

`app/models/user.rb`
```ruby
def self.create_unique_string
  SecureRandom.uuid
end
```

- 継承したregistration_controllerにアクションが起動するようにする

`config/routes.rb`
```ruby
devise_for :users, controllers: {
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
}
```

- ユーザープロフィール用のcarrierwaveの初期設定を行う。

```bash
$ rails generate uploader Avatar
```

- ユーザープロフィール画像を保存するためのカラムを作成する
```bash
$ rails g migration add_avatar_to_users avatar:string
$ rake db:migrate
```

- userモデルに、carrierwave用の設定を行う

`app/models/user.rb`
```ruby
mount_uploader :avatar, AvatarUploader #deviseの設定配下に追記
```


- SNSログインから取得してきた画像を表示させるヘルパーメソッドを作成

`app/helpers/application_helper.rb`
```ruby
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
```

- ユーザー編集ページで画像をアップロードできるようにする

`app/controllers/application_controller.rb`
```ruby
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  #省略

   PERMISSIBLE_ATTRIBUTES = %i(name avatar avatar_cache)

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: PERMISSIBLE_ATTRIBUTES)
      devise_parameter_sanitizer.permit(:account_update, keys: PERMISSIBLE_ATTRIBUTES)
    end
end
```
`avatar avatar_cache` をPERMISSIBLE_ATTRIBUTESに追加する


`app/views/devise/registations/edit.html.erb`

```
<!-- 省略 -->
  <div class="field">
    <%= f.label :現在のパスワード %><br />
    <%= f.password_field :current_password, autocomplete: "off", class: "form-control" %>
  </div>

  <div class="field">
    <%= profile_img(@user) if profile_img(@user) %>
    <%= f.file_field :avatar %>
    <%= f.hidden_field :avatar_cache %>
  </div>

  <div class="actions">
    <%= f.submit "更新", class: "btn btn-primary btn-block" %>
  </div>
<% end %>
<!-- 省略 -->
```

- omniauthでサインアップしたアカウントのユーザ情報の変更出来るようにする

`app/models/user.rb`
```ruby
def update_with_password(params, *options)
  if provider.blank?
    super
  else
    params.delete :current_password
    update_without_password(params, *options)
  end
end
```
update_with_passwordをオーバーライドする。<br>
providerが空だった時は、superでupdate_with_passwordに記述されている内容を上書きし<br>
providerが存在する場合は、current_passwordを削除してパスワードなしでも更新できるようにする。


# トピックに対してのコメント機能の実装

- ルーティングの定義

```ruby
resources :topic do
  resources :comments do
    post :confirm, on: :collection
  end
end
```

- Commentモデルを生成

```bash
$ rails g model Comment user:references topic:references content:text
$ rake db:migrate
```

- UserモデルとTopicモデルにhas_manyを設定（アソシエーション）

`app/models/user.rb`
```ruby
class User < ActiveRecord::Base
#省略
  has_many :topics, dependent: :destroy
  # CommentモデルのAssociationを設定
  has_many :comments, dependent: :destroy
#省略
end
```
`app/models/topic.rb`
```ruby
class Topic < ActiveRecord::Base
#省略
  belongs_to :user
  # CommentモデルのAssociationを設定
  has_many :comments, dependent: :destroy
#省略
end
```

- 投稿機能のためのCommentコントローラにcreateアクションを実装

```bash
$ rails g controller Comments create
```

- config/routes.rbから以下を削除
```ruby
get 'comments/create'
```

- comments_controller.rbに処理を実装

```ruby
class CommentsController < ApplicationController
  # コメントを保存、投稿するためのアクションです。
  def create
    # Topicをパラメータの値から探し出し,Topicに紐づくcommentsとしてbuildします。
    @comment = current_user.comments.build(comment_params)
    @topic = @comment.topic
    # クライアント要求に応じてフォーマットを変更
    respond_to do |format|
      if @comment.save
        format.html { redirect_to topic_path(@topic), notice: 'コメントを投稿しました。' }
      else
        format.html { render :new }
      end
    end
  end

  private
  # ストロングパラメーター
  def comment_params
    params.require(:comment).permit(:topic_id, :content)
  end
end
```

- 必要ないので`views/comments/create.html.erb`を削除

```bash
$ rm app/views/comments/create.html.erb
```

- `app/views/topic/show.html.erb`を作成

```bash
$ touch app/views/topic/show.html.erb
```
```
<p id="notice"><%= notice %></p>
<div>
  <p><%= @topic.comment %></p>
  <p><%= @topic.created_at.strftime("%y/%m/%d %p %l:%M") %></p>
    
  <p>コメント一覧</p>
  <div id="comments_area">
    <%= render partial: 'comments/index', locals: { comments: @comments, topic: @topic } %>
  </div>
  <%= render partial: 'comments/form', locals: { comment: @comment, topic: @topic } %>
  <% if current_user.id == @topic.user_id %>
    <%= link_to '編集', edit_topic_path(@topic) %>
  <% end %>
  <%= link_to '戻る', topic_index_path %>
</div>
```


- コメント入力フォームを作成
```
$ touch app/views/comments/_form.html.erb
```
```
<%= form_for([topic,comment]) do |f| %>
  <% if comment.errors.any? %>
    <div id="error_explanation">
      <h2><%= comment.errors.count %>件のエラーがあります。</h2>

      <ul>
      <% comment.errors.full_messages.each do |msg| %>
        <li><%= msg %></li>
      <% end %>
      </ul>
    </div>
  <% end %>
  <%= f.hidden_field :topic_id %>
  <div class="field">
    <%= f.text_field :content, placeholder: "内容", class: "form-control"  %>
  </div>
  <div class="actions">
    <%= f.submit %>
  </div>
<% end %>
```

- コメント一覧を作成

```bash
$ touch app/views/comments/_index.html.erb
```
```
<ul>
  <% comments.each do |comment| %>
    <% unless comment.id.nil? %>
      <li>
        <p class="left"><%= comment.user.name %>さんがコメントしました。</p>
        <p class="left"><%= comment.content %></p>
        <% if current_user.id == comment.user.id %>
          <p class="right">
            <%= link_to '', edit_topic_comment_path(topic, comment), class: "fa fa-pencil-square-o fa-lg" %>
            <%= link_to '', topic_comment_path(topic, comment), class: "fa fa-trash-o fa-lg", method: :delete, remote: true, data: { confirm: '本当に削除していいですか？' } %>
          </p>
        <% end %>
      </li>
    <% end %>
  <% end %>
</ul>
```

- `app/controllers/topic_controller.rb`にshowアクションを実装
```ruby
 # onlyにshowアクションを追加します。
  before_action :set_topic, only:[:show, :edit, :update, :destroy]
 #省略
  
  # showアククションを定義します。入力フォームと一覧を表示するためインスタンスを2つ生成します。
  def show
    @comment = @topic.comments.build
    @comments = @topic.comments
  end
 #省略
```


- `views/topic/index.html.erb`に詳細画面へのリンクを設定

```
<%= link_to topic_path(topic.id) do %>
  <span class="glyphicon glyphicon-detail" aria-hidden="true"></span>
<% end %>
```

- 非同期でコメントの投稿・編集・更新・削除をする

`app/views/comments/_form.html.erb`
```
<%= form_for([topic, comment], remote: isAsync) do |f| %>
...省略
```

`app/controllers/comments_controller.rb`

```ruby
before_action :set_comment, only: ['edit', 'update', 'destroy']
  
  # コメントを保存、投稿するためのアクションです。
  def create
    # Topicをパラメータの値から探し出し,Topicに紐づくcommentsとしてbuildします。
    @comment = current_user.comments.build(comment_params)
    @topic = @comment.topic
    # respond_toは、クライアントからの要求に応じてレスポンスのフォーマットを変更します。
    respond_to do |format|
      if @comment.save
        format.html { redirect_to topic_path(@topic), notice: 'コメントを投稿しました。' }
        # JS形式でレスポンスを返します。
        format.js { render :index }
      else
        format.html { render :new }
      end
    end
  end

  def edit
    @topic = Topic.find(params[:topic_id])
  end

  def update
    @topic = @comment.topic
    respond_to do |format|
      if @comment.update(comment_params)
        format.html { redirect_to topic_path(@topic), notice: 'コメントを更新しました。' }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @topic = @comment.topic
    respond_to do |format|
      if @comment.destroy
        format.html { redirect_to topic_path(@topic), notice: 'コメントを削除しました。' }
        # JS形式でレスポンスを返します。
        format.js { render :index }
      else
        format.html { render :new }
      end
    end
  end

  private
    # ストロングパラメーター
    def comment_params
      params.require(:comment).permit(:topic_id, :content)
    end

    def set_comment
      @comment = Comment.find(params[:id])
    end
```

- HTMLを再レンダリングするJSファイルを新規作成

```
$ touch app/views/comments/index.js.erb
```
```javascript
$("#comments_area").html("<%= j(render 'comments/index', { comments: @comment.topic.comments, topic: @comment.topic }) %>")
$(':text').val('');
```

- 編集画面を作成（非同期ではなく同期で編集）

```bash
$ touch app/views/comments/edit.html.erb
```
```
<div class="panel panel-default">
  <div class="panel-heading">
    <h4><%= @topic.user.name %>へのコメントを編集</h4></div>
  <div class="panel-body">
    <%= render partial: 'comments/form', locals: { comment: @comment, topic: @topic, isEdit: true } %>
  </div>
</div>
```

- 投稿（非同期）/ 編集・更新（同期）にしたいのでヘルパー関数を作成

`app/helpers/comments_helper.rb`
```ruby
module CommentsHelper
  def isAsync
    if  action_name == 'create'
      true
    elsif action_name == 'update'
      false
    end
  end
end
```


# フォロー機能の作成

- フォローする人とフォローされる人との中間テーブルを作成する

```bash
$ rails g model Relationship follower_id:integer:index followed_id:integer:index
```

- ユーザーを二度フォローできないようにする

`db/migrate/xxxxxxxxx.rb`
```ruby
class CreateRelationships < ActiveRecord::Migration
  def change
    create_table :relationships do |t|
      t.integer :follower_id
      t.integer :followed_id

      t.timestamps null: false
    end
    add_index :relationships, :follower_id
    add_index :relationships, :followed_id
    add_index :relationships, [:follower_id, :followed_id], unique: true
  end
end
```

```bash
$ rake db:migrate
```

### テーブルとの関係性を定義する

- Userが複数のRelationShipを持つことを定義する。

`app/models/user.rb`
```ruby
class User < ActiveRecord::Base
#省略
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :reverse_relationships, foreign_key: "followed_id", class_name: "Relationship", dependent: :destroy
#省略
end
```

- RelationshipがUserに従属することを定義する

`app/models/relationship.rb`
```ruby
class Relationship < ActiveRecord::Base
  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'
end
```

- UserモデルがRelationshipモデルを介して複数のUserを所持することを定義する

`app/models/user.rb`
```ruby
class User < ActiveRecord::Base
#省略
  has_many :followed_users, through: :relationships, source: :followed
  has_many :followers, through: :reverse_relationships, source: :follower
end
```

### ユーザー一覧ページを作成する

- コントローラーとビューを作成

```bash
$ rails g controller users index
```

- コントローラを作成した際に、追加された不要なrouteを削除
`config/routes.rb`
```ruby
 get 'users/index' <- 削除する
```

- routingをresourcesで書き直し

`config/routes.rb`
```ruby
 #devise_forより以下に記述すること
 resources :users, only: [:index]
```

- userを全て取得

`app/controllers/users_controller.rb`
```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
  end
end
```

`app/views/users/index.html.erb`
```
<div>
  <h2>ユーザー</h2>
  <% @users.each do |user| %>
    <div>
      <%= profile_img(user) %>
      <%= user.email %>
      <%= render 'follow_form', user: user %>
    </div>
  <% end %>
</div>
```

### follow機能を作成する

- Routingを作成する

`config/routes.rb`
```ruby
resources :relationships, only: [:create, :destroy]
```

- Controllerを作成する
```bash
$ rails g controller Relationships create destroy
```

- フォローボタンを作成する

```bash
$ touch app/views/users/_follow_form.html.erb
```
```
<div id="follow_form_<%= user.id %>">
  <% unless current_user.following?(user) %>
    <%= form_for(current_user.relationships.build(followed_id: user.id), remote: true) do |f| %>
      <%= f.hidden_field :followed_id %>
      <%= f.submit "フォロー", class: "btn btn-large btn-primary" %>
    <% end %>
  <% end %>
</div>
```

- フォローフォームをユーザー一覧ページから呼び出す。

`app/views/users/index.html.erb`
```
省略
<% @users.each do |user| %>
省略
  <%= render 'follow_form', user: user %>
<% end %>
省略
```

- createメソッドの処理を実装する

`app/controllers/relationships_controller.rb`
```ruby
class RelationshipsController < ApplicationController
  before_action :authenticate_user!
  respond_to :js

  def create
    @user = User.find(params[:relationship][:followed_id])
    current_user.follow!(@user)
    respond_with @user
  end
end
```

- フォロー機能に必要な、メソッドを定義する

`app/models/user.rb`
```ruby
#省略
#指定のユーザをフォローする
def follow!(other_user)
  relationships.create!(followed_id: other_user.id)
end

#フォローしているかどうかを確認する
def following?(other_user)
  relationships.find_by(followed_id: other_user.id)
end
#省略
```

```bash
$ touch app/views/relationships/create.js.erb
```
```javascript
$("#follow_form_"+"<%= @user.id %>").html("<%= escape_javascript(render partial: 'users/follow_form', locals: { user: @user } ) %>")
```

### フォロー解除機能を作成する

- フォロー解除ボタンを実装する

`app/views/users/_follow_form.html.erb`
```
<div id="follow_form_<%= user.id %>">
  <% unless current_user.following?(user) %>
    <%= form_for(current_user.relationships.build(followed_id: user.id), remote: true) do |f| %>
      <%= f.hidden_field :followed_id %>
      <%= f.submit "フォロー", class: "btn btn-large btn-primary" %>
    <% end %>
  <% else %>
    <%= form_for(current_user.relationships.find_by(followed_id: user.id), html: { method: :delete }, remote: true) do |f| %>
      <%= f.submit "つながりを解除", class: "btn btn-large" %>
    <% end %>
  <% end %>
</div>
```

- relationshipsのdestroyメソッドを作成する

`app/controllers/relationships_controller.rb`
```ruby
#省略
def destroy
  @user = Relationship.find(params[:id]).followed
  current_user.unfollow!(@user)
  respond_with @user
end
#省略
```

- unfollowメソッドをモデルに定義する

`app/models/user.rb`
```ruby
#省略
#指定のユーザのフォローを解除する
def unfollow!(other_user)
  relationships.find_by(followed_id: other_user.id).destroy
end
#省略
```

- ajax処理を作成
```bash
$ touch app/views/relationships/destroy.js.erb
```
```javascript
$("#follow_form_"+"<%= @user.id %>").html("<%= escape_javascript(render partial: 'users/follow_form', locals: { user: @user } ) %>")
```


# メッセージ機能を作成

- ルーティングを設定する

`config/routes.rb`
```ruby
resources :conversations do
  resources :messages
end
```

- 会話「conversations」コントローラを作成
```bash
$ rails g controller Conversations index create
```

`config/routes.rb`
```ruby
 get 'conversations/index' <- 削除
 get 'conversations/create'<- 削除
```

- すべてのユーザと会話一覧を取得と作成

`app/controllers/conversations_controller.rb`
```ruby
def index
  @users = User.all  
  @conversations = Conversation.all
end

def create
    if Conversation.between(params[:sender_id], params[:recipient_id]).present?
      @conversation = Conversation.between(params[:sender_id], params[:recipient_id]).first
    else
      @conversation = Conversation.create!(conversation_params)
    end

    redirect_to conversation_messages_path(@conversation)
  end
```

- メッセージコントローラー作成
```bash
$ rails g controller Messages index create
```
`config/routes.rb`にできた余計なルーティングを削除

`app/controllers/messages_controller.rb`
```ruby
class MessagesController < ApplicationController
  before_action do
    @conversation = Conversation.find(params[:conversation_id])
  end

  def index
    @messages = @conversation.messages
    if @messages.length > 10
      @over_ten = true
      @messages = @messages[-10..-1]
    end

    if params[:m]
      @over_ten = false
      @messages = @conversation.messages
    end

    if @messages.last
      if @messages.last.user_id != current_user.id
        @messages.last.read = true
      end
    end

    @message = @conversation.messages.build
  end

  def create
    @message = @conversation.messages.build(message_params)
    if @message.save
      redirect_to conversation_messages_path(@conversation)
    end
  end

  private
    def message_params
      params.require(:message).permit(:body, :user_id)
    end
end
```

- Conversationモデルを作成

```bash
$ rails g model Conversation sender_id:integer recipient_id:integer
```

`app/models/conversation.rb`
```ruby
class Conversation < ActiveRecord::Base
  belongs_to :sender, foreign_key: :sender_id, class_name: 'User'
  belongs_to :recipient, foreign_key: :recipient_id, class_name: 'User'
  has_many :messages, dependent: :destroy
  validates_uniqueness_of :sender_id, scope: :recipient_id
  scope :between, -> (sender_id,recipient_id) do
    where("(conversations.sender_id = ? AND conversations.recipient_id =?) OR (conversations.sender_id = ? AND  conversations.recipient_id =?)", sender_id,recipient_id, recipient_id, sender_id)
  end

  def target_user(current_user)
    if sender_id == current_user.id
      User.find(recipient_id)
    elsif recipient_id == current_user.id
      User.find(sender_id)
    end
  end
end
```

- Messageモデルを作成する

```bash
$ rails g model Message body:text conversation:references user:references read:boolean
```

`app/models/message.rb`
```ruby
class Message < ActiveRecord::Base
  belongs_to :conversation
  belongs_to :user

  validates_presence_of :body, :conversation_id, :user_id
  def message_time
    created_at.strftime("%m/%d/%y at %l:%M %p")
  end
end
```

`db/migrate/xxxxxxxx_create_messages.rb`
```ruby
class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.text :body
      t.references :conversation, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.boolean :read, default: false

      t.timestamps null: false
    end
  end
end
```

- 会話「Conversations」ビューを作成する

`app/views/conversations/index.html.erb`
```
<div class="wrapper col-md-6 col-md-offset-3 col-sm-10 col-sm-offset-1">
  <table class="table table-hover">
    <thead>
    <h2>メッセージ一覧</h2>
    </thead>
    <tbody>
    <% @conversations.each do |conversation| %>
        <td>
          <% if conversation.target_user(current_user).present? %>
              <%= link_to conversation.target_user(current_user).name, conversation_messages_path(conversation)%>
          <% end %>
        </td>
    <% end %>
    </tbody>
  </table>
</div>
```

- ユーザ「Users」ビューの修正

`app/views/users/index.html.erb`
```
<% if user.id != current_user.id %>
  <li>
    <div class="item">
      <%= link_to user.name, user %>
      <%= link_to 'メッセージ', conversations_path(sender_id: current_user.id, recipient_id: user.id), method: 'post'%>
    </div>
    <%= render partial: 'follow_form', locals: { user: user } if signed_in?   %>
  </li>
<% end %>
```

- メッセージ「Messages」ビューの作成

`app/views/messages/index.html.erb`
```
<% if @over_ten %>
  <%= link_to '以前のメッセージ', '?m=all' %>
<% end %>

<div class="ui segment">
  <% @messages.each do |message| %>
    <% if message.body %>
      <% user = User.find(message.user_id) %>
      <div class="item">
        <div class="content">
          <div class="header"><strong><%= user.name %></strong> <%= message.message_time %></div>
          <div class="list">
            <div class="item">
              <i class="right triangle icon"></i>
              <%= message.body %>
            </div>
          </div>
        </div>
      </div>
    <% end %>
  <% end %>
</div>

<%= form_for [@conversation, @message], html: {class: "ui reply form"} do |f| %>
  <div class="field">
    <%= f.text_area :body, class: "form-control" %>
  </div>
    <%= f.text_field :user_id, value: current_user.id, type: "hidden"  %>
  <div>
    <%= f.submit "メッセージを送る" %>
  </div>

<% end %>
```


# AWS関連

- DBリセット
`/var/www/facebook-kayo/current`ディレクトリにて
```bash
bundle exec rake db:migrate RAILS_ENV=production
```

`RAILS_ENV=production`のenvをつけるの、重要！！！

- AWSのnginxのアップロード許容サイズの上限値を変更
`sudo vi /etc/nginx/conf.d/facebook-kayo.conf`
```
upstream unicorn {
  server unix:/var/www/facebook-kayo/shared/tmp/sockets/unicorn.sock;
}

server {
  client_max_body_size 20M; <- これを追加
  listen       80;
  server_name  13.115.11.30;
    
    
  root /var/www/facebook-kayo/shared/public;
    
    access_log /var/log/nginx/facebook-kayo_access.log;
    error_log /var/log/nginx/facebook-kayo_error.log;
    
    location ~ ^/assets/ {
    }
    
    location / {
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_pass http://unicorn;
    }
  }
```
`nginx再起動`

`sudo nginx -s reload`