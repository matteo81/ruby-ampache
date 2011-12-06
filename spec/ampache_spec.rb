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
<root>
    <auth>TOKEN</auth>
    <version>350001</version>
    <update>2011-12-06T16:38Z</update>
    <add>2011-12-06T16:38Z</add>
    <clean>2011-12-06T16:38Z</clean>
    <songs>36</songs>
    <artists>2</artists>
    <albums>3</albums>
    <tags>0</tags>
    <videos>0</videos>
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
      @session.stats.version.should == '350001'
    end
  end
end
