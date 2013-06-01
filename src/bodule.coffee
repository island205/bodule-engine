# bodule-engine
# =============
# 
# **bodule-engine** is a runtime, in which all of the wrapper `node` module are running.
# it's a part of  solution for packing `node` module to browser.


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
        @deps = deps
        @deps = @deps.map (dep) ->
            if dep.indexOf('@') == -1
                dep = Bodule.normalize(self.packageId + '/' + Bodule.dirname(self.path) + '/' + dep)
            dep
        @factory = factory
        @exports = {}
        @compiled = false
        @loaded = false
        @selfCompile = false

    # Bodule property
    @_cache: {},
    @_waitPool : {},
    @_loading : {},
    @__guid: 0,
    # Bodule method
    @config: (@config)->

    @require: (id)->
        bodule = @_cache[id]
        if bodule
            if bodule.compiled
                bodule.exports
            else
                bodule.compile()
                bodule.exports
        else
            throw new Error "bodule #{id} isn't exist"

    @define: (id, deps, factory)->
        console.log "define #{id}"
        bodule = new Bodule(id, deps, factory)
        @_cache[id] = bodule
        bodule.load()

    @use: (mods, callback)->
        id = @_guid()
        console.log "define #{id}"
        bodule = new Bodule(id, mods, callback)
        bodule.selfCompile = true
        @_cache[id] = bodule
        bodule.load()

    @_guid: ->
        "guid@#{@__guid++}"

    @_load: (bodule, parent)->
        waitList = @_waitPool[bodule] ?= []
        if waitList.indexOf(parent) == -1
            waitList.push parent
        return unless not @_loading[bodule]
        @_loading[bodule] = true
        if !Bodule._cache[bodule]
            script = document.createElement 'script'
            src = @config.host + '/' + bodule.replace('@', '/') + '.js'
            script.src = src
            document.head.appendChild script
        return

    @_loaded: (id) ->
        waitList = @_waitPool[id]
        return if not waitList
        for parent in waitList
            Bodule._cache[parent].check()
        return
    @normalize: (path)->
        path = path.replace /\/\.\//g, '/'
        path = path.replace /\/{2,}/g, '/'
        path = path.split '/'
        toPath = []
        while path.length > 0
            top = path.pop()
            if top is '..'
                path.pop()
            else
                toPath.unshift top
        toPath.join '/'
            

    @dirname: (path)->
        path = path.split '/'
        path = path[0...path.length - 1]
        path.join '/'

    # Instance method
    load: ->
        self = @
        deps = @deps.filter (dep)->
            not Bodule._cache[dep] || not Bodule._cache[dep].loaded
        if not deps.length
            @loaded = true
            Bodule._loaded @id
        else
            for dep in deps
                Bodule._load dep, self.id
        return
    check: ->
        deps = @deps.filter (dep)->
            not Bodule._cache[dep] || not Bodule._cache[dep].loaded
        if not deps.length && not @loaded
            @loaded = true
            if @selfCompile
                @compile()
            Bodule._loaded @id

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
        return


do ->
    window.Bodule = Bodule
    window.define = ->
        Bodule.define.apply Bodule, arguments

    Bodule.config
        host: 'http://localhost:8080'
    

    define 'bodule@0.1.0/d', ['basestone@0.0.1/src/basestone'], (require, exports, module)->
        basestone = require 'basestone@0.0.1/src/basestone'
        exports.d = 'd'
        exports.basestone = basestone
        
    define 'bodule@0.1.0/c', ['./d', './e'], (require, exports, module)->
        d = require './d'
        e = require './e'
        exports.cfunc = ->
        exports.d = d
        exports.e = e

    Bodule.use ['bodule@0.1.0/c'], (require, exports, module) ->
        c = require 'bodule@0.1.0/c' 
        console.log c
