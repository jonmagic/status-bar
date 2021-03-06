{$} = require 'space-pen'
Grim = require 'grim'
{Disposable} = require 'atom'
Tile = require './tile'

class StatusBarView extends HTMLElement
  createdCallback: ->
    @classList.add('status-bar')

    flexboxHackElement = document.createElement('div')
    flexboxHackElement.classList.add('flexbox-repaint-hack')
    @appendChild(flexboxHackElement)

    @rightPanel = document.createElement('div')
    @rightPanel.classList.add('status-bar-right', 'pull-right')
    flexboxHackElement.appendChild(@rightPanel)

    @leftPanel = document.createElement('div')
    @leftPanel.classList.add('status-bar-left')
    flexboxHackElement.appendChild(@leftPanel)

    @leftTiles = []
    @rightTiles = []

  initialize: (state) ->
    @bufferSubscriptions = []

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @unsubscribeAllFromBuffer()
      @storeActiveBuffer()
      @subscribeAllToBuffer()

      @dispatchEvent(new CustomEvent('active-buffer-changed', bubbles: true))

    @storeActiveBuffer()
    this

  destroy: ->
    @activeItemSubscription.dispose()
    @unsubscribeAllFromBuffer()
    @remove()

  addLeftTile: (options) ->
    newItem = options.item
    newPriority = options?.priority ? @leftTiles[@leftTiles.length - 1].priority + 1
    nextItem = null
    for {priority, item}, index in @leftTiles
      if priority > newPriority
        nextItem = item
        break

    newTile = new Tile(newItem, newPriority, @leftTiles)
    @leftTiles.splice(index, 0, newTile)
    newElement = atom.views.getView(newItem)
    nextElement = atom.views.getView(nextItem)
    @leftPanel.insertBefore(newElement, nextElement)
    newTile

  addRightTile: (options) ->
    newItem = options.item
    newPriority = options?.priority ? @rightTiles[0].priority + 1
    nextItem = null
    for {priority, item}, index in @rightTiles
      if priority < newPriority
        nextItem = item
        break

    newTile = new Tile(newItem, newPriority, @rightTiles)
    @rightTiles.splice(index, 0, newTile)
    newElement = atom.views.getView(newItem)
    nextElement = atom.views.getView(nextItem)
    @rightPanel.insertBefore(newElement, nextElement)
    newTile

  getLeftTiles: ->
    @leftTiles

  getRightTiles: ->
    @rightTiles

  # Deprecated

  appendLeft: (view) ->
    Grim.deprecate("Use ::addLeftTile({item, priority}) instead.")
    $(@leftPanel).append(view)

  prependLeft: (view) ->
    Grim.deprecate("Use ::addLeftTile({item, priority}) instead.")
    $(@leftPanel).prepend(view)

  appendRight: (view) ->
    Grim.deprecate("Use ::addRightTile({item, priority}) instead.")
    $(@rightPanel).append(view)

  prependRight: (view) ->
    Grim.deprecate("Use ::addRightTile({item, priority}) instead.")
    $(@rightPanel).prepend(view)

  getActiveBuffer: ->
    @buffer

  getActiveItem: ->
    atom.workspace.getActivePaneItem()

  storeActiveBuffer: ->
    @buffer = @getActiveItem()?.getBuffer?()

  subscribeToBuffer: (event, callback) ->
    @bufferSubscriptions.push([event, callback])
    @buffer.on(event, callback) if @buffer

  subscribeAllToBuffer: ->
    return unless @buffer
    for [event, callback] in @bufferSubscriptions
      @buffer.on(event, callback)

  unsubscribeAllFromBuffer: ->
    return unless @buffer
    for [event, callback] in @bufferSubscriptions
      @buffer.off(event, callback)

module.exports = document.registerElement('status-bar', prototype: StatusBarView.prototype)
