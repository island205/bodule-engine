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

# LoadScript
__define 'util', (require, exports, module)->
    head = document.getElementByTagName('head')[0]
    loadScript = (id) ->
        node = document.createElement 'script'
        node.type = 'text/javascript'
        node.async = true
        node.onload = ->
            head.removeChild node
        head.appendChild node
    
    i = 0
    guid = ->
        ++i
    exports.loadScript = loadScript
    exports.guid = guid

# EventEmmiter
__define 'emmiter', (require, exports, module)->
    class EventEmmiter
        constructor: ->
            @__listeners = {}
        listeners: (event)->
            listeners = @listeners
            listeners[event] or listeners[event] = []
        on: (event, listener)->
            @listeners(event).push listener
        emit: (event)->
            args = []
            listeners = @listeners(event).slice()
            if arguments.length > 1
                args = Array::slice arguments
                args.shift()
            for listener in listeners
                listener.apply @, args

    module.exports = EventEmmiter
 
__define 'module', (require, exports, module)->
    util = require 'util'
    EventEmmiter = require 'emmiter'
    STATUS =
        INIT:       0
        FETCHING:   1
        SAVED:      2
        LOADING:    3
        LOADED:     4
        EXECUTING:  5
        EXECUTED:   6
    class Module extends EventEmmiter
        @modules = {}
        @get: (id, deps, factory)->
            module = @modules[id]
            if module
                module.deps = deps
                module.factory = factory
            else
                moudle = new Module id, deps, factory
            modules[id] = module
        @define: (id, deps, factory)->
            module = @get id, deps, factory
            module.state = STATUS.SAVED
            module.loadDeps()
            module
        @use: (module)->
            require = (id)=>
                module = @get id
                module.exports or module.exports = @use module
            exports = module.exports = {}
            module.factory(require, exports, module)
            module.exports
        constructor: (@id, @deps=[], @factory)->
            @exports = null
            @state = STATUS.INIT
            super
        loadDeps: ()->
            depModules = []
            if @state > STATUS.LOADING
                return
            @state = STATUS.LOADING

            for dep in @deps
                module = Module.get dep
                module.on 'loaded', @isDepsLoaded
                depModules.push module
            @depModules = depModules
            @isDepsLoaded()

            for module in depModules
                if module.state < STATUS.FETCHING
                    module.fetch()
                else if moudle.state is STATUS.SAVED
                    module.loadDeps()
        isDepsLoaded: =>
            loaded = true
            for module in @depModules
                if module.state < STATUS.LOADED
                    loaded = false
            if loaded
                @emit 'loaded'
        fetch: ->
            if @state > STATUS.FETCHING
                util.loadScript id
                return
            @state = STATUS.FETCHING

    module.exports = Module

# Bodule
__define 'bodule', (require, exports, module)->
    Module = require 'module'
    util  = require 'util'
    Bodule =
        use: (deps, factory)->
            module = Module.get '_use_' + util.guid(), deps, factory
            module.on 'loaded', ->
                Module.use module
            module.loadDeps()
        define: (id, deps, factory)->
            Module.define id, deps, factory
    module.exports = Bodule

# API
__use 'bodule', (require)->
    Bodule = require 'bodule'
    window.Bodule
    window.define = ()->
        Bodule.apply(Bodule, arguments)
