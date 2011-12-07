dir = File.dirname(__FILE__)
$LOAD_PATH.unshift dir unless $LOAD_PATH.include?(dir)

require 'Qt4'
require 'ampache'
require 'models'
require 'searchedit'

class MainWidget < Qt::Widget
  slots 'show_albums(const QModelIndex&)'
  slots 'show_songs(const QModelIndex&)'
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
    @buttons = []
    @artist_button = Qt::PushButton.new 'Artists' do |b|
      b.connect(SIGNAL :clicked) { stack_show :artist }
    end
    @album_button = Qt::PushButton.new 'Albums' do |b|
      b.connect(SIGNAL :clicked) { stack_show :album }
    end
    @song_button = Qt::PushButton.new 'Songs' do |b|
      b.connect(SIGNAL :clicked) { stack_show :song }
    end
    @playlist_button = Qt::PushButton.new 'Playlist' do |b|
      b.connect(SIGNAL :clicked) { stack_show :playlist }
    end
    
    @buttons << @artist_button << @album_button << @song_button << @playlist_button
    
    button_layout = Qt::HBoxLayout.new do |l|
      @buttons.each do |button|
        button.checkable = true
        button.checked = false
        l.add_widget button
      end
    end
  
    @collection_view = Qt::ListView.new
    @album_view = Qt::ListView.new
    @songs_view = Qt::ListView.new
    @playlist_view = Qt::ListView.new
    #@collection_view.style_sheet = "border-style: null"
    @filter_input = SearchEdit.new
    
    @stack = Qt::StackedWidget.new
    @stack.add_widget @collection_view
    @stack.add_widget @album_view
    @stack.add_widget @songs_view
    @stack.add_widget @playlist_view
    
    layout = Qt::VBoxLayout.new(self) do |l|
      l.add_layout button_layout
      l.add_widget @filter_input
      l.add_widget @stack
    end
    
    stack_show :artist
    
    Qt::Object.connect( @collection_view, SIGNAL('activated(const QModelIndex&)'),
                        self, SLOT( 'show_albums(const QModelIndex&)' ) )
    Qt::Object.connect( @album_view, SIGNAL('activated(const QModelIndex&)'),
                        self, SLOT( 'show_songs(const QModelIndex&)' ) )
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
      @collection_model = CollectionModel.new Ampache::Session.instance
      @proxy_model = Qt::SortFilterProxyModel.new
      @proxy_model.source_model = @collection_model
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
  
  def show_albums(index)
    orig_index = @proxy_model.map_to_source index
    selected_item = @collection_model.data(orig_index, Qt::UserRole).value
    @album_model = AlbumModel.new selected_item
    @album_view.set_model @album_model
    
    stack_show :album
  end
  
  def show_songs(index)
    selected_item = @album_model.data(index, Qt::UserRole).value
    @song_model = SongModel.new selected_item
    @songs_view.set_model @song_model
    
    stack_show :song
  end
  
  def stack_show(widget)
    case widget
    when :artist
      check_button @artist_button
      @stack.current_index = 0
    when :album
      check_button @album_button
      @stack.current_index = 1
    when :song 
      check_button @song_button
      @stack.current_index = 2
    when :playlist
      check_button @playlist_button
      @stack.current_index = 3
    end
  end
  
  def check_button(button)
    @buttons.each do |b|
      b.checked = (button == b)
    end
  end
end
