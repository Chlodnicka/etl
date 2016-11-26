class ChangeColumnTypesInReview < ActiveRecord::Migration
  def up
    change_column :reviews, :pros, :text
    change_column :reviews, :cons, :text
  end

  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :reviews, :pros, :string
    change_column :reviews, :cons, :string
  end
end
