# Implements:
#
#   initialize
#   iam_policy
#   managed_iam_policy
#   logical_id
#   role_name
#
module Jets::Cfn::TemplateMappers::IamPolicy
  class ApplicationPolicyMapper < BasePolicyMapper
    def initialize; end # does nothing

    # Assume we always have at least some baseline iam policy permissions.
    def iam_policy
      Jets::Cfn::TemplateBuilders::IamPolicy::ApplicationPolicy.new
    end
    memoize :iam_policy

    def managed_iam_policy
      return unless Jets.config.managed_iam_policy

      Jets::Cfn::TemplateBuilders::ManagedIamPolicy::ApplicationPolicy.new
    end
    memoize :managed_iam_policy

    # Example: PostsControllerLambdaFunction
    # Note there are is no "Show" action in the name
    def logical_id
      "IamRole" # very simple logical ideal for the application-wide logical id
    end

    # There should be namespace in the role_name.
    def role_name
      "#{namespace}_application_iam_role".underscore.dasherize
    end
  end
end