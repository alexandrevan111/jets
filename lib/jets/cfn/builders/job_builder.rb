# Implements:
#
#   compose
#   template_path
#
class Jets::Cfn::Builders
  class JobBuilder < BaseChildBuilder
    def compose
      add_common_parameters
      add_functions
      add_resources
    end
  end
end
