class ChangeTimeColumnTypeInReviews2 < ActiveRecord::Migration
  def up
    remove_column :reviews, :time
    add_column :reviews, :time, :datetime
  end
end
