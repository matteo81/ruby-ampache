require '../lib/lib-classes'

describe AmpacheSong do
  before :each do
    @songs = []
    @songs << AmpacheSong.new(nil, "1", "Nice title", "John Doe", "It's me", "http://some.where/on/the/net", 1)
    @songs << AmpacheSong.new(nil, "108", "My way", "John Doe", "It's me", "http://some.where/on/the/net", 3)
    @songs << AmpacheSong.new(nil, "109", "Astonishing", "John Doe", "It's me", "http://some.where/on/the/net", 2)
  end
  
  it 'should exist' do
    @songs.first.should_not == nil
  end
  
  it 'should order in the correct way' do
    @songs.last.title.should == "Astonishing"
    @songs.sort!    
    @songs.last.title.should == "My way"
    @songs.first.track.should == 1
    @songs[1].uid.should == "109" 
  end
end
