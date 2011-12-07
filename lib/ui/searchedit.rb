class SearchEdit < Qt::LineEdit
  slots 'updateCloseButton(QString)'
  
  def initialize(parent = nil)
    super(parent)
    
    @clear_button = Qt::ToolButton.new(self)
    @clear_button.icon = Qt::Icon.new(Qt::Pixmap.new(File.dirname(__FILE__) + '/edit-clear-locationbar-rtl.png'))
    @clear_button.cursor = Qt::Cursor.new(Qt::ArrowCursor)
    @clear_button.style_sheet = 'QToolButton { border: none; padding: 0px; }'
    @clear_button.hide
    
    @search_button = Qt::ToolButton.new(self)
    @search_button.icon = Qt::Icon.new(Qt::Pixmap.new(File.dirname(__FILE__) + '/search.png'))
    @search_button.icon_size = @clear_button.icon_size
    @search_button.cursor = Qt::Cursor.new(Qt::ArrowCursor)
    @search_button.style_sheet = 'QToolButton { border: none; padding: 0px; }'
        
    set_text_margins(@search_button.size_hint.width * 1.25, 0, 0, 0)
    
    @clear_button.connect(SIGNAL :clicked) { clear }
    @search_button.connect(SIGNAL :clicked) { emit returnPressed }
    connect( self, SIGNAL( "textChanged(const QString&)" ), self, SLOT( "updateCloseButton(const QString&)" ) )
  end
  
  def resizeEvent(event)
    sz = @clear_button.size_hint
    frame_width = style.pixel_metric(Qt::Style::PM_DefaultFrameWidth)
    @clear_button.move(rect.right - frame_width - sz.width, (rect.bottom + 1 - sz.height)/2)
    @search_button.move(rect.left + sz.width/3, (rect.bottom + 1 - sz.height)/2)
  end
  
  def updateCloseButton(text)
    @clear_button.visible = !text.empty?
  end
end
