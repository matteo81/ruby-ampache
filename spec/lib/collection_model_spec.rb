require 'ampache'
require 'models'
require 'parseconfig'

describe CollectionModel do
  it 'should not initialize empty' do
    lambda{ CollectionModel.new }.should raise_error
  end

  it "Should Implement QAbstractListModel" do
    CollectionModel.ancestors.should include Qt::AbstractListModel
  end

  describe 'with a working Ampache session' do
    before :each do
      @ampache = Ampache::Session.from_config_file
      @model = CollectionModel.new @ampache
    end

    it 'should have some data' do
      @model.rowCount.should > 0
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

    it 'should not have correct data when accessing out of bounds' do
      @model.data(mock_index(-10, 0)).should_not be_valid
      @model.data(mock_index(100, 0)).should_not be_valid
    end

    it "Should Not Be Editable" do
      @model.data(mock_index(1,0), Qt::EditRole).should_not be_valid
      @model.headerData(nil, nil, Qt::EditRole).should_not be_valid
                              
      flags = @model.flags(nil)
      flags.should have_flag Qt::ItemIsEnabled
      flags.should have_flag Qt::ItemIsSelectable
      flags.should_not have_flag Qt::ItemIsEditable
    end
  end
end
