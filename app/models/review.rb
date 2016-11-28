class Review < ActiveRecord::Base
  belongs_to :product


  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_names
      all.each do |review|
        csv << review.attributes.values_at(*column_names)
      end
    end
  end

end
