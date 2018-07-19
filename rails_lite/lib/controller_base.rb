require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require 'active_support/inflector'

class ControllerBase
  attr_reader :req, :res, :params
  
  # Setup the controller
  def initialize(req, res)
    @req = req
    @res = res
    @already_built_response = false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise 'already rendered' if @already_built_response
    @res.header['location'] = url
    @res.status = 302
    @session.store_session(@res)
    @already_built_response = true
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise 'already rendered' if @already_built_response
    @res["Content-Type"] = content_type
    @res.write(content)
    @already_built_response = true
    @session.store_session(@res)
    @res.finish
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    parent_folder = File.dirname(__FILE__)
    root_dir = File.dirname(parent_folder)
    class_name = self.class.to_s
    file_path = "#{root_dir}/views/#{class_name.underscore}/#{template_name}.html.erb"
    file_contents = File.read(file_path)
    erbed_contents = ERB.new(file_contents).result(binding)
    render_content(erbed_contents, 'text/html')
    # @res.finish
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
  end
end

