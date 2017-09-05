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