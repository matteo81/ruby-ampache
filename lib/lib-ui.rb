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
 
        # artist model (defined simply as a stringlist)
        # see model/view programming
        # http://doc.qt.nokia.com/latest/model-view-programming.html    
        @artistModel = Qt::StringListModel.new
        @albumModel = Qt::StringListModel.new
        
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
        names = []
        # extract the name from AmpacheArtist
        # TODO: don't lose the uid
        artists.each do |artist|
            names << artist.name
        end
        # initialize the model
        @artistModel.setStringList names
        
        # set the model to the view
        @artistListView.setModel @artistModel
    end
    
    def updateAlbums(index)
        @albumListView.setModel Qt::StringListModel.new
        Thread.new do
            # Get the selected artist
            # TODO: should return the AmpacheArtist instead of just a string containing the name
            artist = @artistModel.data(index, Qt::DisplayRole).value

            # TODO: this is highly inefficient
            # Must avoid to call @ampache.artists again
            albums = @ampache.albums(@ampache.artists(artist).first)
            names=[]
            
            albums.each do |album|
                names << album.name
            end
            # initialize the model
            @albumModel.setStringList names
            @albumListView.setModel @albumModel
        end
    end
end