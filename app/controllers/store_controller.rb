class StoreController < ApplicationController

  def show2
    @product = Product.find(params['id'])
  end
  
end