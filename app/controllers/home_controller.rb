class HomeController < ApplicationController
  layout 'home'
  # GET /products
  # GET /products.json
  # Get homepage
  def index
    @products = Product.all
    @product = Product.new
  end


  private
  #Get product param
  def product_params
    params.require(:product).permit(:code)
  end
end
