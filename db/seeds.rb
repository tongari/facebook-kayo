# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

10.times do |idx|
  name = Faker::Name.name
  email = Faker::Internet.email
  password = 'password'
  User.create!(
    name: name,
    email: email,
    password: password,
    password_confirmation: password,
    provider: '',
    uid: SecureRandom.uuid,
    current_sign_in_at: Time.new,
    last_sign_in_at: Time.new,
    confirmed_at: Time.new,
    confirmation_sent_at: Time.new
  )

  Topic.create!(
    photo: '',
    comment: "#{Faker::DragonBall.character} is great!",
    user_id: rand(10) + 1
  )
end