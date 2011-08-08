RSpec::Matchers.define :render_403 do
  match { |r| r.status == 403 }
end

RSpec::Matchers.define :render_404 do
  match { |r| r.status == 404 }
end
