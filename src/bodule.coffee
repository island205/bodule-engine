class Bodule
    # Constructor
    constructor: (id, deps, factory) ->
        [@package, @version] = id.split '@'
        @version = @version.split '/'
        @path = @version.slice 1, @version.length
        @version = @version[0]
        @path = @path.join '/'
        @packageId = "#{@package}@#{@version}"
        @id = id
        @deps = deps
        @factory = factory
        @exports = {}
        @loaded = false
        @load()

    # Bodule property
    @_cache: {},

    # Bodule method
    @config: (@config)->

    @require: (id)->
        @_cache[id].exports

    @define: (id, deps, factory)->
        bodule = new Bodule(id, deps, factory)
        @_cache[id] = bodule

    @_load: (bodule, onload)->
        script = document.createElement 'script'
        src = @config.host + '/' + bodule.replace('@', '/') + '.js'
        script.src = src
        script.onload = onload
        document.head.appendChild script
        return

    @normalize: (path)->
        path.replace /\/{2,}/g, '/'
    @dirname: (path)->
        path = path.split '/'
        path = path[0...path.length - 1]
        path.join '/'

    # Instance method
    load: ->
        self = @
        deps = @deps.map (dep) ->
            if dep.indexOf('@') == -1
                dep = Bodule.normalize(self.packageId + '/' + Bodule.dirname(self.path) + '/' + dep)
            dep
        deps = deps.filter (dep)->
            !Bodule._cache[dep]
        if not deps.length
            self.compile()
        else
            for dep in deps
                if !Bodule._cache[dep]
                    Bodule._load dep, ->
                            isLoaded = true
                            for dep in deps
                                if !Bodule._cache[dep]
                                    isLoaded = false
                            if isLoaded
                                self.compile()
        return
    compile: ->
        self = @
        module = {}
        exports = module.exports = @exports
        require  = (id) =>
            # Is a relative module
            if id.indexOf('@') == -1
                id = "#{@packageId}#{id}"
            Bodule.require id
        @factory(require, exports, module)
        @exports = module.exports
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
        
    define 'bodule@0.1.0/c', ['/d', '/e'], (require, exports, module)->
        d = require '/d'
        e = require '/e'
        console.log d
        console.log e
        exports.cfunc = ->
            console.log d
