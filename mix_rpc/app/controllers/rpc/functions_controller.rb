module Rpc
  class FunctionsController < ActionController::API
    include ActionController::RequestForgeryProtection

    prepend_before_action :set_format
    # TODO protect_from_forgery with: :exception

    def call
      function.call! params: params.require(:rpc_function).to_unsafe_h
      render json: function.result
    rescue ActiveRecord::RecordInvalid
      log Rpc::FunctionError.new(function)
      render json: function.error_hash, status: :not_acceptable
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def function
      @function ||= Rpc::Function.find(params[:id])
    end

    def set_format
      request.format = :json
    end
  end
end
