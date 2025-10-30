module LibController::WithUserEtag
  def etag_context
    super.concat([
      Current.role,
      Current.user.as_role,
      Current.user.updated_at,
    ])
  end
end
