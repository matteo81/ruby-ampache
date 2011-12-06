require 'ampache'

describe Ampache::Session do
  it 'should raise an exception when the options are wrong' do
    lambda { Ampache::Session.handshake('http://foo/ampache', 'foo', 'foo') }.should raise_error
  end
  
  it 'should not allow creating a new session' do
    lambda { Ampache::Session.new }.should raise_error
  end
  
  context 'with a working Ampache server' do
    before :each do
      @session = Ampache::Session.instance
      Ampache::Session.instance.stub(:call_api_method) do |method, args|
          Nokogiri::XML(<<EOS) if method == "handshake"
<?xml version="1.0" encoding="UTF-8" ?>
<root>
        <auth><![CDATA[TOKEN]]></auth>
        <api><![CDATA[350001]]></api>
        <update><![CDATA[2011-12-06T01:00:00+01:00]]></update>
        <add><![CDATA[2011-12-06T06:25:36+01:00]]></add>
        <clean><![CDATA[2011-12-06T06:25:29+01:00]]></clean>
        <songs><![CDATA[36]]></songs>
        <albums><![CDATA[3]]></albums>
        <artists><![CDATA[2]]></artists>
        <playlists><![CDATA[0]]></playlists>
        <videos><![CDATA[0]]></videos>

</root>
EOS
      end
         
      Ampache::Session.handshake('', '', '')
    end
    
    it 'should have stats' do
      @session.stats.should_not be_nil
    end
    
    it 'should not allow altering the stats' do
      lambda { @session.stats.songs = 21 }.should raise_error
    end
    
    it 'should parse the stats correctly' do
      @session.token.should == 'TOKEN'
      @session.stats.update.year.should == 2011
      @session.stats.update.month.should == 12
      @session.stats.update.day.should == 6
      @session.stats.songs.should == 36
      @session.stats.api.should == '350001'
    end
  end
end
