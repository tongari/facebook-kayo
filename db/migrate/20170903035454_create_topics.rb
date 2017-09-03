class CreateTopics < ActiveRecord::Migration
  def change
    create_table :topics do |t|
      t.string :photo
      t.text :comment

      t.timestamps null: false
    end
  end
end
