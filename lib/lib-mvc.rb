require 'Qt4'
require File.join(File.dirname(__FILE__), 'lib-ampache')
require File.join(File.dirname(__FILE__), 'lib-classes')

class CollectionModel < Qt::AbstractListModel
  def initialize(ampache, parent = nil)
    super(parent)

    @artists = ampache.artists
  end

  def rowCount(parent = nil)
    @artists.count
  end

  def data(index, role = Qt::DisplayRole)
    item = @artists[index.row]
    return invalid if item.nil?

    return Qt::Variant.new(item.name) if role == Qt::DisplayRole
    return Qt::Variant.from_value(item) if role == Qt::UserRole
    return invalid
  end

  def headerData(section, orientation, role)
    return invalid unless role == Qt::DisplayRole

    'artist' if orientation == Qt::Horizontal
  end

  def flags(index)
    return Qt::ItemIsSelectable | Qt::ItemIsEnabled
  end

  private
    def invalid
      Qt::Variant.new
    end
end
