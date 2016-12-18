class ReviewsController < ApplicationController
  before_action :set_review, only: [:show]

  # GET /reviews
  # GET /reviews.json
  # Get all reviews or generates CSV file
  def index
    @reviews = Review.all
    respond_to do |format|
      format.html
      format.csv { send_data @reviews.to_csv }
    end
  end

  # GET /reviews/1
  # GET /reviews/1.json
  # Get specific review
  def show
  end

  private
  # Set review variable depending on id
  def set_review
    @review = Review.find(params[:id])
  end

end
