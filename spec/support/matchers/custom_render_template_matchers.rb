module CustomRenderTemplateMatchers

  include Spec::Rails::Matchers

  def render_403
    render_template("#{RAILS_ROOT}/public/403.html")
  end

  def render_404
    render_template("#{RAILS_ROOT}/public/404.html")
  end

end
