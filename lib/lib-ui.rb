require 'Qt4'

class MainWidget < Qt::Widget
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
        @artistList = Qt::ListView.new(self);
 
		# initialize the layout of the main widget
        layout = Qt::VBoxLayout.new(self) do |l|
            l.add_widget(@artistList)
            l.add_widget(button)
        end
		
		# do some initialization
		# using a separate thread to avoid GUI freeze
		initialize = Thread.new do
			# attempt to connect to Ampache server
			initializeConnection
			
			# artist model (defined simply as a stringlist)
			# see model/view programming
			# http://doc.qt.nokia.com/latest/model-view-programming.html
			@artistModel = Qt::StringListModel.new do |model|
				artists = @ampache.artists
 				names = []
				# extract the name from AmpacheArtist
				# TODO: don't lose the uid
 				artists.each do |artist|
 					names << artist.name
 				end
				# initialize the model
				model.setStringList names
			end
			
			# set the model to the view
			@artistList.setModel @artistModel
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
end