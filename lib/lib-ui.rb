require 'Qt4'

class CollectionProxyModel <  Qt::SortFilterProxyModel
  def initialize
    super
  end
  
  def filterAcceptsRow(sourceRow, sourceParent)
    return true if sourceParent.is_valid and not source_model.item(sourceRow).text.empty?
    
    super
  end
end

class MainWidget < Qt::MainWindow
  slots 'update_collection(const QModelIndex&)'
  slots 'filter_collection(const QString&)'
  slots 'add_to_playlist(const QModelIndex&)'
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
        
    # various models
    # see model/view programming
    # http://doc.qt.nokia.com/latest/model-view-programming.html
    @playlist_model = Qt::StandardItemModel.new
    @collection_model = Qt::StandardItemModel.new
    
    # layout the widgets
    splitter = Qt::Splitter.new(self)
    set_central_widget(splitter)
  
    @filter_input = Qt::LineEdit.new
    @collection_view = Qt::TreeView.new
    @collection_view.header_hidden = true
    layout = Qt::VBoxLayout.new do |l|
      l.add_widget @filter_input
      l.add_widget @collection_view
    end
    collection_and_filter = Qt::Widget.new(splitter)
    collection_and_filter.set_layout layout
    @playlist_view = Qt::ListView.new(splitter)
    
    Qt::Object.connect( @collection_view, SIGNAL('activated(const QModelIndex&)'),
                        self, SLOT( 'update_collection(const QModelIndex&)' ) )
    Qt::Object.connect( @collection_view, SIGNAL('doubleClicked(const QModelIndex&)'),
                        self, SLOT( 'add_to_playlist(const QModelIndex&)' ) )
    Qt::Object.connect( @filter_input, SIGNAL('textChanged(const QString&)'),
                        self, SLOT( 'filter_collection(const QString&)' ) )
    
    @proxy_model = CollectionProxyModel.new
    @proxy_model.set_source_model @collection_model
    
    # Enable ruby threading
    @ruby_thread_sleep_period = 0.01
    @ruby_thread_timer = Qt::Timer.new(self)
    connect(@ruby_thread_timer, SIGNAL('timeout()'), SLOT('ruby_thread_timeout()'))
    @ruby_thread_timer.start(0)
    
    @collection_mutex = Mutex.new
  
    # do some initialization
    # using a separate thread to avoid GUI freeze
    initialize = Thread.new do
      initialize_connection
      update_artists
    end
    
    @collection_view.set_model @proxy_model
    @playlist = AmpachePlaylist.new
  end

  def initialize_connection
    begin
      ar_config = ParseConfig.new(File.expand_path('~/.ruby-ampache'))
      $options = {}
      $options[:path] = ar_config.get_value('MPLAYER_PATH')
      $options[:timeout] = ar_config.get_value('TIMEOUT').to_i
    rescue
      raise "\nPlease create a .ruby-ampache file on your home\n See http://github.com/ghedamat/ruby-ampache for infos\n"
    end
    
    @ampache = AmpacheRuby.new(ar_config.get_value('AMPACHE_HOST'), ar_config.get_value('AMPACHE_USER'), ar_config.get_value('AMPACHE_USER_PSW'))
    puts @ampache.stats
  end
    
  def update_artists
    artists = @ampache.artists
            
    parent_item = @collection_model.invisible_root_item
    # for every artist extract the name (which will be displayed)
    # and the whole class (attached as data)
    artists.each do |artist|
      item = Qt::StandardItem.new(artist.name)
      # attach the AmpacheArtist object as Data (to extract additional info)
      item.set_data(Qt::Variant.from_value(artist), Qt::UserRole)
      item.editable = false
      @collection_model.append_row(item)
    end
  end
    
  def update_collection(index)
    Thread.new do
      @collection_mutex.synchronize {
        orig_index = index
        index = @proxy_model.map_to_source(index) unless @filter_input.text.empty?
        selected_item = @collection_model.item_from_index(index)
        return if selected_item.has_children    
  
        case @collection_model.data(index, Qt::UserRole).value
          when AmpacheArtist then update_albums(index)
          when AmpacheAlbum then update_songs(index)
        end
      
        unless @filter_input.text.empty?
          filter_collection(@filter_input.text) 
        else
          @collection_view.expand index
        end
      }
   end
  end
  
  def update_albums(index)
    selected_item = @collection_model.item_from_index(index)
    albums = @ampache.albums(@collection_model.data(index, Qt::UserRole).value).sort
        
    albums.each do |album|
      string = album.name unless album.name.empty?
      string += " (#{album.year})" unless (album.year.nil? or album.year == 0)
      item = Qt::StandardItem.new(string)
      # attach the AmpacheAlbum object as Data (to extract additional info)
      item.set_data(Qt::Variant.from_value(album), Qt::UserRole)
      item.editable = false
      selected_item.append_row item
    end
  end
  
  def update_songs(index)
    selected_item = @collection_model.item_from_index(index)
    songs = @ampache.songs(@collection_model.data(index, Qt::UserRole).value).sort
      
    songs.each do |song|
      string = "#{song.track}. #{song.title}"
      item = Qt::StandardItem.new(string)
      # attach the AmpacheSong object as Data (to extract additional info)
      item.setData(Qt::Variant.from_value(song), Qt::UserRole)
      item.setEditable false
      selected_item.append_row item
    end
  end
  
  def add_to_playlist(index)
    @playlist.stop
    @playlist = AmpachePlaylist.new
    @collection_model.data(index, Qt::UserRole).value.add_to_playlist @playlist
    update_playlist
  end
  
  def closeEvent(event)
    @playlist.stop
    event.accept
  end
      
  def filter_collection(text)
    if text.empty?
      @collection_view.set_model @collection_model
      return
    end
    
    # the following line is needed to avoid "ghost" items
    @proxy_model.set_source_model @collection_model
    @proxy_model.filter_reg_exp = text
    @proxy_model.filter_case_sensitivity = Qt::CaseInsensitive
    
    # for some reason, this doesn't seem to work
    @collection_view.expand_all
  end
  
  def update_playlist
    @playlist_model = Qt::StandardItemModel.new
    @playlist.each do |song|
      string = "#{song.track}. #{song.title}"
      item = Qt::StandardItem.new(string)
      # attach the AmpacheSong object as Data (to extract additional info)
      item.setData(Qt::Variant.from_value(song), Qt::UserRole)
      item.setEditable false
      
      @playlist_model.append_row item
    end
    
    @playlist_view.set_model @playlist_model
  end
end