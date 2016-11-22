class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.text :summary
      t.string :pros
      t.string :cons
      t.float :starts
      t.string :recommendation
      t.integer :useful
      t.integer :not_useful
      t.string :author
      t.references :product, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
