require '../lib/lib-ampache'

require 'parseconfig'

describe AmpacheRuby do
  before :each do
    begin
      ar_config = ParseConfig.new(File.expand_path('~/.ruby-ampache'))
    rescue
      raise "\nPlease create a .ruby-ampache file on your home\n See http://github.com/ghedamat/ruby-ampache for infos\n"
    end
    @ar = AmpacheRuby.new(ar_config.get_value('AMPACHE_HOST'), ar_config.get_value('AMPACHE_USER'), ar_config.get_value('AMPACHE_USER_PSW'))
  end
  
  it 'should exist' do
    @ar.nil?.should == false
  end
  
  it 'should raise when the options are wrong' do
    lambda { AmpacheRuby.new('http://foo/ampache', 'foo', 'foo') }.should raise_error
  end
  
  it 'should have stats' do
    @ar.stats.artists.should > 0
    @ar.stats.albums.should > 0
    @ar.stats.songs.should > 0
  end
end
