dir = File.dirname(__FILE__)
$LOAD_PATH.unshift dir unless $LOAD_PATH.include?(dir)

require 'Qt4'
require 'ampache'
require 'models'
require 'searchedit'

class MainWidget < Qt::Widget
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
        
    # layout the widgets
    
    artist_button = Qt::PushButton.new 'Artists'
    album_button = Qt::PushButton.new 'Albums'
    song_button = Qt::PushButton.new 'Songs'
    playlist_button = Qt::PushButton.new 'Playlist'
    
    button_layout = Qt::HBoxLayout.new do |l|
      l.add_widget artist_button
      l.add_widget album_button
      l.add_widget song_button
      l.add_widget playlist_button
    end
  
    @collection_view = Qt::ListView.new
    #@collection_view.style_sheet = "border-style: null"
    @filter_input = SearchEdit.new
    
    layout = Qt::VBoxLayout.new(self) do |l|
      l.add_layout button_layout
      l.add_widget @filter_input
      l.add_widget @collection_view
    end
    
#     Qt::Object.connect( @collection_view, SIGNAL('activated(const QModelIndex&)'),
#                         self, SLOT( 'update_collection(const QModelIndex&)' ) )
#     Qt::Object.connect( @collection_view, SIGNAL('doubleClicked(const QModelIndex&)'),
#                         self, SLOT( 'add_to_playlist(const QModelIndex&)' ) )
    Qt::Object.connect( @filter_input, SIGNAL('textChanged(const QString&)'),
                        self, SLOT( 'filter_collection(const QString&)' ) )
    
    # Enable ruby threading
    @ruby_thread_sleep_period = 0.01
    @ruby_thread_timer = Qt::Timer.new(self)
    connect(@ruby_thread_timer, SIGNAL('timeout()'), SLOT('ruby_thread_timeout()'))
    @ruby_thread_timer.start(0)
    
    initialize = Thread.new do
      initialize_connection
      # various models
      # see model/view programming
      # http://doc.qt.nokia.com/latest/model-view-programming.html
      source_model = CollectionModel.new Ampache::Session.instance
      @proxy_model = Qt::SortFilterProxyModel.new
      @proxy_model.source_model = source_model
      @proxy_model.filter_case_sensitivity = Qt::CaseInsensitive
      @collection_view.set_model @proxy_model
    end  

    #@proxy_model = CollectionProxyModel.new
    #@proxy_model.set_source_model @collection_model
  end

  def initialize_connection
    Ampache::Session.from_config_file
    puts Ampache::Session.instance.stats
  end
  
  def filter_collection(search_string)
    @proxy_model.filter_reg_exp = search_string
  end
  
  def closeEvent(event)
    event.accept
  end
end
