RSpec::Matchers.define :have_flag do |flag|
  match do |given|
    given & flag != 0
  end
end

