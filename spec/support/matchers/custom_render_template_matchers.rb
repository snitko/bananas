module CustomRenderTemplateMatchers

  include Spec::Rails::Matchers

  def render_403
    render_template("#{Rails.root}/public/403.html")
  end

  def render_404
    render_template("#{Rails.root}/public/404.html")
  end

end
