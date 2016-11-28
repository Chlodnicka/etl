class ReviewsController < ApplicationController
  before_action :set_review, only: [:show, :edit, :update, :destroy]

  # GET /reviews
  # GET /reviews.json
  def index
    @reviews = Review.all
    respond_to do |format|
      format.html
      format.csv { send_data @reviews.to_csv }
    end
  end

  # GET /reviews/1
  # GET /reviews/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_review
      @review = Review.find(params[:id])
    end

end
