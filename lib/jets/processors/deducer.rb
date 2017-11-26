# Jets::Processors::Deducer class figures out information that allows the
# controller or job to be called. Sme key methods for deducer:
#
#   code - code to instance eval.  IE: PostsController.new(event, context).index
#   path - full path to the app code. IE: #{Jets.root}app/controllers/posts_controller.rb
#
class Jets::Processors
  class Deducer
    def initialize(handler)
      @handler = handler # handlers/controllers/posts.show
      # @handler_path: "handlers/controllers/posts"
      # @handler_method: "show"
      @handler_path, @handler_method = @handler.split('.')
    end

    def code
      # code: "PostsController.new(event, context, meth: "show").show"
      # code: "HardJob.new(event, context, meth: "dig").dig"
      %|#{class_name}.process(event, context, "#{@handler_method}")|
    end

    # Input: @handler_path: handlers/jobs/hard_job.rb
    # Output: #{Jets.root/app/jobs/hard_job.rb
    def path
      Jets.root.to_s + @handler_path.sub("handlers", "app") + ".rb"
    end

    # process_type is key. It can be either "controller" or "job". It is used to
    # deduce the rest of the methods: code, path.
    def process_type
      @handler.split('/')[1].singularize # controller or job
    end

    # Example underscored_class_name:
    #   class_name = underscored_class_name
    #   class_name = class_name # PostsController
    def class_name
      regexp = Regexp.new(".*handlers/#{process_type.pluralize}/")
      # Example regexp:
      #   /.*handlers\/controllers\//
      #   /.*handlers\/jobs\//
      class_name = @handler_path.sub(regexp, "")
      # Example class names:
      #   posts_controller
      #   hard_job
      #   hello
      #   hello_function

      class_name.classify
    end

    def load_class
      Jets::Klass.from_path(path)
    end

  end
end
