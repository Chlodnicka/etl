json.extract! review, :id, :summary, :pros, :cons, :starts, :recommendation, :useful, :not_useful, :author, :product_id, :created_at, :updated_at
json.url review_url(review, format: :json)