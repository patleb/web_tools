module Rpc
  class FunctionsController < LibApiController
    def call
      function.call! params: function_params
      render json: function.result
    rescue ActiveRecord::RecordInvalid
      log Rpc::FunctionError.new(function)
      render json: function.error_hash, status: :not_acceptable
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def function_params
      params[:rpc_function]&.to_unsafe_h || {}
    end

    def function
      @function ||= Rpc::Function.find(params[:id])
    end
  end
end
