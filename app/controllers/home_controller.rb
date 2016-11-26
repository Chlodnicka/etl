class HomeController < ApplicationController
  layout 'home'
  # GET /products
  # GET /products.json
  def index
    @products = Product.all
    @product = Product.new
  end


  private
  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(:code)
  end
end
