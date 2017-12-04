<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :set_<%= singular_table_name %>, only: [:show, :edit, :update, :delete]

  # GET <%= route_url %>
  def index
    @<%= plural_table_name %> = <%= orm_class.all(class_name) %>
  end

  # GET <%= route_url %>/1
  def show
  end

  # GET <%= route_url %>/new
  def new
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
  end

  # GET <%= route_url %>/1/edit
  def edit
  end

  # POST <%= route_url %>
  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{singular_table_name}_params") %>

    if @<%= orm_instance.save %>
      redirect_to "/<%= plural_table_name %>/#{@<%= singular_table_name %>.id}"
    else
      render :new
    end
  end

  # PUT <%= route_url %>/1
  def update
    if @<%= orm_instance.update("#{singular_table_name}_params") %>
      redirect_url = "/<%= plural_table_name %>/#{@<%= singular_table_name %>.id}"
      if request.xhr?
        puts "xhr put call"
        render json: {success: true, location: redirect_url} # local
      else
        puts "standard http put call"
        redirect_to redirect_url
      end
    else
      render :edit
    end
  end

  # DELETE <%= route_url %>/1
  def delete
    @<%= orm_instance.destroy %>
    if request.xhr?
      render json: {success: true}
    else
      redirect_to "/<%= plural_table_name %>"
    end
  end

private
  # Use callbacks to share common setup or constraints between actions.
  def set_<%= singular_table_name %>
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
  end

  def <%= "#{singular_table_name}_params" %>
    <%- if attributes_names.empty? -%>
    params.fetch(:<%= singular_table_name %>, {})
    <%- else -%>
    params[:<%= singular_table_name %>]
    <%- end -%>
  end
end
<% end -%>
