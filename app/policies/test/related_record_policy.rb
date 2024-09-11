module Test
  class RelatedRecordPolicy < ApplicationPolicy
    def index?
      true
    end

    def export?
      true
    end

    def show?
      true
    end

    def new?
      true
    end

    def edit?
      true
    end

    def delete?
      true
    end

    class Scope < Scope
      def resolve
        relation.all
      end
    end
  end
end
