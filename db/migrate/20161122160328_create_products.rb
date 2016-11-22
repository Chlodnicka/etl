class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :code
      t.string :brand
      t.string :model
      t.string :type
      t.string :notes

      t.timestamps null: false
    end
  end
end
