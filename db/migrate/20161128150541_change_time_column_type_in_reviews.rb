class ChangeTimeColumnTypeInReviews < ActiveRecord::Migration
  def up
    change_column :reviews, :time, :float
  end

  def down
    change_column :reviews, :time, :float
  end
end
