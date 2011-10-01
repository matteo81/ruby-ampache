require 'Qt4'

class MainWidget < Qt::Widget
    slots 'updateAlbums(const QModelIndex&)'
	def initialize(parent=nil)
		super(parent)
		
        self.window_title = 'Ramp'
		# resize to a sane value
		# TODO: load/save on startup/close
        resize(800, 400)
 
        button = Qt::PushButton.new('Quit', self) do
            connect(SIGNAL :clicked) { Qt::Application.instance.quit }
        end
		
		# the list widget showing the artists
        @artistListView = Qt::ListView.new(self)
        
        Qt::Object.connect( @artistListView, SIGNAL('clicked(const QModelIndex&)'),
                  self, SLOT( 'updateAlbums(const QModelIndex&)' ) )
        @albumListView = Qt::ListView.new(self);
 
        # various models
        # see model/view programming
        # http://doc.qt.nokia.com/latest/model-view-programming.html
        @artistModel = Qt::StandardItemModel.new
        @albumModel = Qt::StandardItemModel.new
        
		# initialize the layout of the main widget
        layout = Qt::VBoxLayout.new(self) do |l|
            l.add_widget(@artistListView)
            l.add_widget(@albumListView)
            l.add_widget(button)
        end
		
		# do some initialization
		# using a separate thread to avoid GUI freeze
		initialize = Thread.new do
			# attempt to connect to Ampache server
			initializeConnection
			
            updateArtists
		end
    end
	
	def initializeConnection
		begin
			ar_config = ParseConfig.new(File.expand_path('~/.ruby-ampache'))
		rescue
			raise "\nPlease create a .ruby-ampache file on your home\n See http://github.com/ghedamat/ruby-ampache for infos\n"
		end
		
		@ampache =AmpacheRuby.new(ar_config.get_value('AMPACHE_HOST'), ar_config.get_value('AMPACHE_USER'), ar_config.get_value('AMPACHE_USER_PSW'))
	end
    
    def updateArtists
        artists = @ampache.artists
                
        # for every artist extract the name (which will be displayed)
        # and the whole class (attached as data)
        artists.each do |artist|
            item = Qt::StandardItem.new(artist.name)
            item.setData(Qt::Variant.fromValue(artist), Qt::UserRole)
            @artistModel.appendRow item
        end
        
        # set the model to the view
        @artistListView.setModel @artistModel
    end
    
    def updateAlbums(index)
        @albumListView.setModel Qt::StandardItemModel.new
        @albumModel = Qt::StandardItemModel.new
        Thread.new do
            # Get the selected artist
            albums = @ampache.albums(@artistModel.data(index, Qt::UserRole).value)
            
            albums.each do |album|
                item = Qt::StandardItem.new(album.name)
                item.setData(Qt::Variant.fromValue(album), Qt::UserRole)
                @albumModel.appendRow item
            end
            
            @albumListView.setModel @albumModel
        end
    end
end