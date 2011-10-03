require 'Qt4'

class MainWidget < Qt::Widget
  slots 'updateAlbums(const QModelIndex&)'
  slots 'playAlbum(const QModelIndex&)'
  
  slots 'ruby_thread_timeout()'

  def ruby_thread_timeout
    sleep(@ruby_thread_sleep_period)
  end

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
    Qt::Object.connect( @artistListView, SIGNAL('activated(const QModelIndex&)'),
              self, SLOT( 'updateAlbums(const QModelIndex&)' ) )
    
    @albumListView = Qt::ListView.new(self);
    Qt::Object.connect( @albumListView, SIGNAL('doubleClicked(const QModelIndex&)'),
              self, SLOT( 'playAlbum(const QModelIndex&)' ) )
    
    # various models
    # see model/view programming
    # http://doc.qt.nokia.com/latest/model-view-programming.html
    @artistModel = Qt::StandardItemModel.new
    @albumModel = Qt::StandardItemModel.new
    @albumMutex = Mutex.new
      
    # initialize the layout of the main widget
    layout = Qt::VBoxLayout.new(self) do |l|
      l.add_widget(@artistListView)
      l.add_widget(@albumListView)
      l.add_widget(button)
    end
      
    # Enable ruby threading
    @ruby_thread_sleep_period = 0.01
    @ruby_thread_timer = Qt::Timer.new(self)
    connect(@ruby_thread_timer, SIGNAL('timeout()'), SLOT('ruby_thread_timeout()'))
    @ruby_thread_timer.start(0)
  
    # do some initialization
    # using a separate thread to avoid GUI freeze
    initialize = Thread.new do
      # attempt to connect to Ampache server
      initializeConnection
      updateArtists
    end
    
    @playlist = AmpachePlaylist.new
  end

  def initializeConnection
    begin
      ar_config = ParseConfig.new(File.expand_path('~/.ruby-ampache'))
      $options = {}
      $options[:path] = ar_config.get_value('MPLAYER_PATH')
      $options[:timeout] = ar_config.get_value('TIMEOUT').to_i
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
      # attach the AmpacheArtist object as Data (to extract additional info)
      item.setData(Qt::Variant.fromValue(artist), Qt::UserRole)
      item.setEditable false
      @artistModel.appendRow item
    end
    
    @artistListView.setModel @artistModel
  end
    
  def updateAlbums(index)
    @albumListView.setModel Qt::StandardItemModel.new
    
    Thread.new do
      @albumMutex.synchronize {
        @albumModel = Qt::StandardItemModel.new
        albums = @ampache.albums(@artistModel.data(index, Qt::UserRole).value).sort
        
        albums.each do |album|
          string = album.name
          string += " (#{album.year})" if !album.year.nil?
          item = Qt::StandardItem.new(string)
          # attach the AmpacheAlbum object as Data (to extract additional info)
          item.setData(Qt::Variant.fromValue(album), Qt::UserRole)
          item.setEditable false
          @albumModel.appendRow item
        end
        
        @albumListView.setModel @albumModel
      }
    end
  end
  
  def playAlbum(index)
    @albumModel.data(index, Qt::UserRole).value.add_to_playlist(@playlist) 
  end
end