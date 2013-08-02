# BODULE-ENGINE
# =============
# 
# **BODULE-ENGINE** is a runtime, in which all of the wrapper `node` module are running.
# it's a part of  solution for packing `node` module to browser.

# CommonJS seed RUNTIME
__modules = {}

__require = (id)->
    module = __modules[id]
    module.exports or module.exports = __use module.factory

__define = (id, factory)->
    __modules[id] =
        id: id
        factory:factory

__use = (factory)->
    module = {}
    exports = module.exports = {}
    factory __require, exports, module
    module.exports

# EventEmmiter
__define 'emmiter', (require, exports, module)->
    class EventEmmiter
        constructor: ->
            @__listeners = {}
        listeners: (event)->
            listeners = @listeners
            listeners[event] or listeners[event] = []
        once: (event, listener)->
            once = =>
                @off event, listener
                listener.apply @, arguments
            once.__listener = listener
            @on event, once
        on: (event, listener)->
            @listeners(event).push listener
        off: (event, listener)->
            index = -1
            listeners = @listeners event
            for lis in listeners
                if lis is listener or lis.listener is listener
                    index = i
            if index isnt -1
                listeners.splice index, 1
        emit: (event)->
            args = []
            listeners = @listeners(event).slice()
            if arguments.length > 1
                args = Array::slice arguments
                args.shift()
            for listener in listeners
                listener.apply @, args

    module.exports = EventEmmiter
 
__define 'state', (require, exports, module)->
    EventEmmiter = require 'emmiter'
    class State extends EventEmmiter
    module.exports = State
    
 
__define 'module', (require, exports, module)->
    class Module extends State
    module.exports = Module
