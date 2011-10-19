require '../lib/lib-classes'
require 'nokogiri'

describe AmpacheSong do
  before :each do
    @songs = []
    
    xmldoc = Nokogiri::XML(<<eos
<root>
<song id="1">
        <title>Nice title</title>
        <artist id="12">John Doe</artist>
        <album id="2">It's me</album>
        <track>1</track>
        <time>198</time>
        <url>http://some.where/on/the/net</url>
        <size>1241300</size>
        <art>http://localhost/image.php?id=129348</art>
        <rating>2.9</rating>
</song>
<song id="108">
        <title>My way</title>
        <artist id="12">John Doe</artist>
        <album id="2">It's me</album>
        <track>3</track>
        <time>241</time>
        <url>http://some.where/on/the/net</url>
        <size>121300</size>
        <art>http://localhost/image.php?id=1239348</art>
        <rating>3</rating>
</song>
<song id="109">
        <title>Astonishing</title>
        <artist id="12">John Doe</artist>
        <album id="2">It's me</album>
        <track>2</track>
        <time>312</time>
        <url>http://some.where/on/the/net</url>
        <size>141300</size>
        <art>http://localhost/image.php?id=1291348</art>
        <rating>3.1</rating>
</song>
</root>
eos
    )
    xmldoc.xpath("//song").each do |a|
      @songs << AmpacheSong.new(self, a)
    end
    @song = @songs.first
  end
  
  it 'should exist' do
    @songs.first.should_not == nil
  end
  
  it 'should order in the correct way' do
    @songs.last.title.should == "Astonishing"
    @songs.sort!    
    @songs.last.title.should == "My way"
    @songs.first.track.to_i.should == 1
    @songs[1].uid.should == "109" 
  end
end
