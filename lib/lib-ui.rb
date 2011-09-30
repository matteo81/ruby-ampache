require 'Qt4'

class MainWidget < Qt::Widget
	def initialize(parent=nil)
		super(parent)
		
        self.window_title = 'Ramp'
        resize(800, 400)
 
        button = Qt::PushButton.new('Quit', self) do
            connect(SIGNAL :clicked) { Qt::Application.instance.quit }
        end
		
        @artistList = Qt::ListView.new(self);
 
        layout = Qt::VBoxLayout.new(self) do |l|
            l.add_widget(@artistList)
            l.add_widget(button)
        end
		
		initialize = Thread.new do
			initializeConnection
			
			@artistModel = Qt::StringListModel.new do |model|
				artists = @ampache.artists
 				names = []
 				artists.each do |artist|
 					names << artist.name
 				end
				model.setStringList names
			end
			
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