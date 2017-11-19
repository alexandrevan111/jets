require 'json'

# Jets::Lambda::Function is the superclass of:
#   Jets::Controller::Base
#   Jets::Job::Base
module Jets::Lambda
  class Function
    include Dsl

    attr_reader :event, :context, :meth
    def initialize(event, context, meth)
      @event = event # Hash, JSON.parse(event) ran BaseProcessor
      @context = context # Hash. JSON.parse(context) ran in BaseProcessor
      @meth = meth
      # store meth because it is useful to for identifying the which template
      # to use later.
    end
  end
end
