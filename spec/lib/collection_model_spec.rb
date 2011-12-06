require 'ampache'
require 'models'
require 'parseconfig'
require 'spec_helper'

describe CollectionModel do
  it 'should not initialize empty' do
    lambda{ CollectionModel.new }.should raise_error
  end

  it "Should Implement QAbstractListModel" do
    CollectionModel.ancestors.should include Qt::AbstractListModel
  end

  describe 'with a working Ampache session' do
    before :each do
      Ampache::Session.instance.stub(:call_api_method) do |method, args|
        Nokogiri::XML(<<eos) if method == "artists"
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
      end
      @model = CollectionModel.new Ampache::Session.instance
    end

    it 'should have some data' do
      @model.rowCount.should == 2
    end

    it 'should fetch data' do
      index = mock_index 0,0 
      data = @model.data(index)
      data.should be_valid
      data.should_not be_nil
    end

    it 'should return correct types depending on role' do
      index = mock_index 0,0
      @model.data(index).value.should be_an_instance_of String
      @model.data(index, Qt::UserRole).value.should be_an_instance_of Ampache::Artist
    end
                       
    it 'should parse the data correctly depending on role' do
      index = mock_index 1,0
      @model.data(index).value.should == 'The Arcade Fire'
      artist = @model.data(index, Qt::UserRole).value
      artist.name.should == "The Arcade Fire"
    end

    it 'should not have correct data when accessing out of bounds' do
      @model.data(mock_index(-10, 0)).should_not be_valid
      @model.data(mock_index(2, 0)).should_not be_valid
    end

    it 'should not be editable' do
      @model.data(mock_index(1,0), Qt::EditRole).should_not be_valid
      @model.headerData(nil, nil, Qt::EditRole).should_not be_valid
                              
      flags = @model.flags(nil)
      flags.should have_flag Qt::ItemIsEnabled
      flags.should have_flag Qt::ItemIsSelectable
      flags.should_not have_flag Qt::ItemIsEditable
    end
  end
end
