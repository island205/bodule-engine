# BODULE-ENGINE
# 
# **BODULE-ENGINE** is a runtime, in which all of the wrapper `node` module are running.
# it's a part of  solution for packing `node` module to browser.


# Seed runtime
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


# Util
__define 'util', (require, exports, module)->
    # Script loader util
    head = document.getElementsByTagName('head')[0]
    loadScript = (id, callback) ->
        node = document.createElement 'script'
        node.type = 'text/javascript'
        node.async = true
        node.src = "#{id}.js"
        node.onload = ->
            callback()
            head.removeChild node
             
        head.appendChild node
    
    # Guid
    i = 0
    guid = ->
        ++i

    exports.loadScript = loadScript
    exports.guid = guid


# Path
__define 'path', (require, exports, module)->

    DIRNAME_REG = /[^?#]*\//
    ROOT_DIR_REG = /^.*?\/\/.*?\//
    MORE_THAN_TWO_SLASH_REG = /([^:]\/)(\/{1,})/
    DOT_REG = /\/\.\//
    DOUBLE_DOT_REG = /\/[^/]+\/\.\.\//


    dirname = (path)->
        path.match(DIRNAME_REG)[0]

    resolve = (from, to)->
        fisrt = to.charAt 0
        if fisrt is '.'
            path = dirname(from) + to
        if fisrt is '/'
            match = from.match ROOT_DIR_REG
            path = match[0] + to.substring(0)
        path

    normalize = (path)->
        path = path.replace MORE_THAN_TWO_SLASH_REG, '$1' while path.match MORE_THAN_TWO_SLASH_REG
        path = path.replace DOT_REG, '/' while path.match DOT_REG
        path = path.replace DOUBLE_DOT_REG, '/' while path.match DOUBLE_DOT_REG
        path

    exports.dirname = dirname
    exports.resolve = resolve
    exports.normalize = normalize


# EventEmmiter
__define 'emmiter', (require, exports, module)->

    class EventEmmiter
        constructor: ->
            @__listeners = {}
        listeners: (event)->
            listeners = @__listeners
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
 

# Module
__define 'module', (require, exports, module)->

    util = require 'util'
    EventEmmiter = require 'emmiter'
    path = require 'path'

    STATUS = 
        INIT:       0
        FETCHING:   1
        SAVED:      2
        LOADING:    3
        LOADED:     4
        EXECUTING:  5
        EXECUTED:   6

    moduleData = null

    class Module extends EventEmmiter
        # Static
        @modules = {}
        @get: (id, deps, factory)->
            module = @modules[id]
            if module
                module.deps = deps.map (dep)->
                    dep = path.resolve id, dep
                    dep = path.normalize dep
                module.factory = factory
            else
                module = new Module id, deps, factory
            @modules[id] = module
        @define: (id, deps, factory)->
            moduleData =
                deps: deps,
                factory: factory
        @require: (id)=>
            module = @modules[id]
            module.exports or module.exports = @use module
        @use: (module)->
            module.exec()
            module.exports
        @save: (id, deps, factory)->
            module = @get id, deps, factory
            module.state = STATUS.SAVED
            module.loadDeps()

        # Instance
        constructor: (@id, @deps=[], @factory)->
            @deps = @deps.map (dep)=>
                dep = path.resolve @id, dep
                dep = path.normalize dep
            @exports = null
            @state = STATUS.INIT
            super
        exec: ->
            __require = (id)=>
                id = path.resolve @id, id
                id = path.normalize id
                Module.require id
            __module = {}
            __exports = __module.exports = {}
            @factory(__require, __exports, __module)
            @exports = __module.exports
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
                @state = STATUS.LOADED
                @emit 'loaded'
        fetch: ->
            if @state < STATUS.FETCHING
                util.loadScript @id, =>
                    Module.save @id, moduleData.deps, moduleData.factory
                return
            @state = STATUS.FETCHING

    module.exports = Module


# Config
__define 'config', (require, exports, module)->
    path = require 'path'
    config =
        cwd: path.dirname location.href

    exports.config = (conf)->
        if arguments.length is 0
            config
        else
            for key, value of conf
                config[key] = value
            config


# Bodule
__define 'bodule', (require, exports, module)->

    Module = require 'module'
    util  = require 'util'
    path = require 'path'
    config = require 'config'

    # Bodule API
    Bodule =
        use: (deps, factory)->
            id = path.resolve config.config().cwd, "./_use_#{util.guid()}"
            id = path.normalize id
            module = Module.get id, deps, factory
            module.on 'loaded', ->
                Module.use module
            module.loadDeps()
        define: (id, deps, factory)->
            Module.define id, deps, factory
        Module: Module

    module.exports = Bodule


# API
__use (require)->

    Bodule = require 'bodule'

    window.Bodule = Bodule
    window.define = ()->
        Bodule.define.apply(Bodule, arguments)
