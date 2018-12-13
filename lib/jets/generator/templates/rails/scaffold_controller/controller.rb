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
      if request.xhr?
        render json: {success: true, location: url_for("/<%= plural_table_name %>/#@{<%= singular_table_name %>.id}")}
      else
        redirect_to "/<%= plural_table_name %>/#{@<%= singular_table_name %>.id}"
      end
    else
      render :new
    end
  end

  # PUT <%= route_url %>/1
  def update
    if @<%= orm_instance.update("#{singular_table_name}_params") %>
      if request.xhr?
        render json: {success: true, location: url_for("/<%= plural_table_name %>/#@{<%= singular_table_name %>.id}")}
      else
        redirect_to "/<%= plural_table_name %>/#{@<%= singular_table_name %>.id}"
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
    params.require(:<%= singular_table_name %>).permit(<%= attributes_names.map { |name| ":#{name}" }.join(', ') %>)
    <%- end -%>
  end
end
<% end -%>
