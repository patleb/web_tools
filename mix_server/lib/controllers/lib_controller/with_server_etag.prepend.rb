module LibController::WithServerEtag
  def etag_context
    super << MixServer.current_version
  end
end
