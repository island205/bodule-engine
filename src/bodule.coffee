class Bodule
    # Bodule property
    @_cache: {},
    @require: (id)->
        @_cache[id].compile()

    @define: (id, deps, factory)->
        bodule = new Bodule(id, deps, factory)
        @_cache[id] = bodule

    # Bodule method
    @_load: (request, parent)->
        caheBodule = @_cache[request]
        if cacheBodule
            return cacheBodule.exports

        bodule = new Bodule(request, parent)
        bodule.load()
        bodule.compile()
        bodule.exports

    # Constructor
    constructor: (id, deps, factory) ->
        @id = id
        @deps = parent
        @factory = factory
        @children = []
        @exports = {}
        @loaded = false

        parent?.children?.push @
        return

    # Instance method
    load: ->
        ###
        Sync or Async load, base env
        ###
    compile: ->
        module = {}
        exports = module.exports = @exports
        require  = Bodule.require
        @factory(require, exports, module)
        @exports = module.exports
        return
