class AddColumnsAndRenameThemReview < ActiveRecord::Migration
  def change
    rename_column :reviews, :starts, :time
    add_column :reviews, :code, :string
    add_column :reviews, :score, :float
  end
end
