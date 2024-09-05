# frozen_string_literal: true

module MixJob
  module Routes
    def self.draw(mapper)
      mapper.post '/_jobs/:job_class/:job_id' => 'jobs#create', as: :jobs
    end

    def self.root_path(**params)
      append_query '/_jobs', params
    end

    def self.job_path(job_class:, job_id:, **params)
      build_path job_class, job_id, *params
    end

    include ExtRails::WithRoutes
  end
end
