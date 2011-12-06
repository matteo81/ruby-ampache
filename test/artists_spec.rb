require '../lib/lib-classes'
require 'nokogiri'

describe AmpacheArtist do
  before :each do
    @artists = []
    xmldoc = Nokogiri::XML(<<eos)
<root>
<artist id="12039">
  <name>Metallica</name>
  <albums>15</albums>
  <songs>52</songs>
  <tag id="2481" count="2">Rock & Roll</tag>
  <tag id="2482" count="1">Rock</tag>
  <tag id="2483" count="1">Roll</tag>
  <preciserating>3</preciserating>
  <rating>2.9</rating>
</artist>
<artist id="271">
  <name>The Arcade Fire</name>
  <albums>3</albums>
  <songs>15</songs>
  <preciserating>4</preciserating>
  <rating>4.9</rating>
</artist>
</root>
eos
    xmldoc.xpath("//artist").each do |a|
      @artists << AmpacheArtist.new(self, a)
    end
    @artist = @artists.first
  end
  
  it 'should exist' do
    @artist.nil?.should == false
    @artists.count.should == 2
  end
  
  it 'should parse the right id' do
    @artist.uid.should == '12039'
  end
  
  it 'should return all the artist information' do
    @artist.name.should == "Metallica"
    @artist.rating.to_f.should == 2.9
    @artist.preciserating.to_i.should == 3
    @artist.songs.to_i.should == 52
  end
end
