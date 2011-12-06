RSpec::Matchers.define :have_flag do |flag|
  match do |given|
    given & flag != 0
  end
end

def mock_index(row, col)
  stub(:row => row, :column => col)
end
