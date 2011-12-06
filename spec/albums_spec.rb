require 'ampache'
require 'nokogiri'

describe Ampache::Album do
  before :each do
    @albums = []
    xmldoc = Nokogiri::XML(<<eos)
<root>
<album id="2910">
  <name>Back in Black</name>
  <artist id="129348">AC/DC</artist>
  <year>1984</year>
  <tracks>12</tracks>
  <disk>1</disk>
  <tag id="2481" count="2">Rock & Roll</tag>
  <tag id="2482" count="1">Rock</tag>
  <tag id="2483" count="1">Roll</tag>
  <art>http://localhost/image.php?id=129348</art>
  <preciserating>3</preciserating>
  <rating>2.9</rating>
</album>
<album id="2917">
  <name>Back in Red</name>
  <artist id="129348">AC/DC</artist>
  <year>1986</year>
  <tracks>11</tracks>
  <disk>1</disk>
  <tag id="2481" count="2">Rock & Roll</tag>
  <tag id="2482" count="1">Rock</tag>
  <tag id="2483" count="1">Roll</tag>
  <preciserating>3.3</preciserating>
  <rating>2.1</rating>
</album>
<album id="2918">
  <name>Back in Red</name>
  <artist id="129348">AC/DC</artist>
  <year>1986</year>
  <tracks>15</tracks>
  <disk>2</disk>
  <tag id="2481" count="2">Rock & Roll</tag>
  <tag id="2482" count="1">Rock</tag>
  <tag id="2483" count="1">Roll</tag>
  <preciserating>3.2</preciserating>
  <rating>2.0</rating>
</album>
<album id="2919">
  <name>Back in Blue</name>
  <artist id="129348">AC/DC</artist>
  <year>1982</year>
  <tracks>12</tracks>
  <disk>1</disk>
  <rating>2.9</rating>
</album>
</root>
eos
    xmldoc.xpath("//album").each do |a|
      @albums << Ampache::Album.new(a)
    end
    @album = @albums.first
  end
  
  it 'exists' do
    @album.nil?.should == false
    @albums.count.should == 4
  end
  
  it 'parses the right id' do
    @album.uid.should == '2910'
  end
  
  it 'returns all the album information' do
    @album.name.should == "Back in Black"
    @album.artist.should == "AC/DC"
    @album.preciserating.to_f.should == 3.0
    @album.tracks.to_i.should == 12
    lambda { @album.song }.should raise_error
    lambda { @albums.last.preciserating }.should raise_error
  end
  
  it 'compares correctly' do
    @albums[1].name.should == @albums[2].name
  end
  
  it 'sorts correctly' do
    sorted = @albums.sort
    sorted.first.uid.should == '2919'
    sorted.last.uid.should == '2918'
  end

  it 'should be enumerable' do
    @albums.all? { |album| album.uid.should_not be_nil }
    @albums.find { |album| album.uid == '2918'}.disk.to_i.should == 2
  end
end
