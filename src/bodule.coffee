class Bodule
    # Constructor
    constructor: (id, deps, factory) ->
        self = @
        [@package, @version] = id.split '@'
        @version = @version.split '/'
        @path = @version.slice 1, @version.length
        @version = @version[0]
        @path = @path.join '/'
        @packageId = "#{@package}@#{@version}"
        @id = id
        console.log "new Bodule #{@id}"
        @deps = deps
        @deps = @deps.map (dep) ->
            if dep.indexOf('@') == -1
                dep = Bodule.normalize(self.packageId + '/' + Bodule.dirname(self.path) + '/' + dep)
            dep
        @factory = factory
        @exports = {}
        @compiled = false

    # Bodule property
    @_cache: {},
    @_waitPool : {},

    # Bodule method
    @config: (@config)->

    @require: (id)->
        @_cache[id].exports

    @define: (id, deps, factory)->
        bodule = new Bodule(id, deps, factory)
        @_cache[id] = bodule
        bodule.load()

    @_load: (bodule, parent)->
        waitList = @_waitPool[bodule] ?= []
        if waitList.indexOf(parent) == -1
            waitList.push parent
        if !Bodule._cache[bodule]
            script = document.createElement 'script'
            console.log "load module #{bodule}"
            src = @config.host + '/' + bodule.replace('@', '/') + '.js'
            script.src = src
            document.head.appendChild script
        return

    @_compiled: (id) ->
        waitList = @_waitPool[id]
        return if not waitList
        for parent in waitList
            Bodule._cache[parent].check()
        return
    @normalize: (path)->
        path.replace /\/\.\//g, '/'
        path.replace /\/{2,}/g, '/'

    @dirname: (path)->
        path = path.split '/'
        path = path[0...path.length - 1]
        path.join '/'

    # Instance method
    load: ->
        self = @
        deps = @deps.filter (dep)->
            !Bodule._cache[dep] || !Bodule._cache[dep].compiled
        if not deps.length
            @compile()
        else
            for dep in deps
                Bodule._load dep, self.id
        return
    check: ->
        console.log "check #{@id}"
        deps = @deps.filter (dep)->
            not Bodule._cache[dep] || not Bodule._cache[dep].compiled
        if not deps.length
            @compile()

    compile: ->
        console.log "compile module #{@id}"
        self = @
        module = {}
        exports = module.exports = @exports
        require  = (id) =>
            # Is a relative module
            if id.indexOf('@') == -1
                id = Bodule.normalize(@packageId + '/' + Bodule.dirname(@path) + '/' + id)
            Bodule.require id
        @factory(require, exports, module)
        @exports = module.exports
        @compiled = true
        Bodule._compiled @id
        return


do ->
    Bodule.config
        host: 'http://localhost:8080'
    window.define = ->
        Bodule.define.apply Bodule, arguments
    
    define 'bodule@0.1.0/d', ['basestone@0.0.1/src/basestone'], (require, exports, module)->
        basestone = require 'basestone@0.0.1/src/basestone'
        exports.d = 'd'
        exports.basestone = basestone
        
    define 'bodule@0.1.0/c', ['./d', './e'], (require, exports, module)->
        d = require './d'
        e = require './e'
        exports.cfunc = ->
            console.log d
