# **bodule-engine** is a runtime, in which all of the wrapper `node` module are running.
# it's a part of  solution for packing `node` module to browser.
# it learn from [Sea.js](http://seajs.org/) a lot.


# **Seed runtime**

# This is a **private** CommonJS runtime for `bodule.js`.
# I use `node` module style to orgnize code.

# `__modules` for store private module like `util`,`path`, and so on.
__modules = {}

# `__require` is used for getting module's API: `exports` property.
__require = (id)->
    module = __modules[id]
    module.exports or module.exports = __use module.factory

# Define a module, save module in `__modules`. use `id` to refer them.
__define = (id, factory)->
    __modules[id] =
        id: id
        factory:factory

# `__use` to start a CommonJS runtime, or get a module's exports.
__use = (factory)->
    module = {}
    exports = module.exports = {}

    # In factory `call`, `this` is global
    factory __require, exports, module
    module.exports


# **util**
__define 'util', (require, exports, module)->

    head = document.getElementsByTagName('head')[0]
    
    # **util.loadScript**

    # Pass a `callback`, when module is loaded, saving the deps and factory of the module  
    # to `Bodule.modules[id]`.
    loadScript = (id, callback) ->
        node = document.createElement 'script'
        node.type = 'text/javascript'
        node.async = true
        
        # `id` is a absolute URI like `http://example.com/a`
        node.src = "#{id}.js"
        node.onload = ->
            callback()
            head.removeChild node
             
        head.appendChild node
    
    # **util.guid**

    # `guid()` will return `1,2,3,4,5,6...`
    i = 0
    guid = ->
        ++i

    exports.loadScript = loadScript
    exports.guid = guid


# **path**

# Deal with url path
__define 'path', (require, exports, module)->
    
    # Head to [http://www.regexper.com/](http://www.regexper.com/), visual regexp.
    DIRNAME_REG = /[^?#]*\//
    ROOT_DIR_REG = /^.*?\/\/.*?\//
    MORE_THAN_TWO_SLASH_REG = /([^:]\/)(\/{1,})/
    DOT_REG = /\/\.\//
    DOUBLE_DOT_REG = /\/[^/]+\/\.\.\//

    # **path.dirname**

    # `https://github.com/Bodule/bodule-engine` => `https://github.com/Bodule/` or  
    # `/Bodule/bodule-engine` => `/Bodule/`
    dirname = (path)->
        path.match(DIRNAME_REG)[0]
    
    # **path.resolve**
    #
    # `resolve('https://github.com/Bodule/bodule-engine', './path')` =>  
    #     `'https://github.com/Bodule/path'`
    #
    # `resolve('https://github.com/Bodule/bodule-engine', '/path')` =>  
    #     `'https://github.com/path'`
    #
    # `resolve('https://github.com/Bodule/bodule-engine', 'path')` =>  
    #     `'path'`
    resolve = (from, to)->
        fisrt = to.charAt 0
        if fisrt is '.'
            path = dirname(from) + to
        if fisrt is '/'
            match = from.match ROOT_DIR_REG
            path = match[0] + to.substring(0)
        path

    # **path.normalize**
    #
    # Remove `/./` `//` `/../` and so on.
    normalize = (path)->
        # JavaScript doesn't support `(?<!exp)`, so use group.
        path = path.replace MORE_THAN_TWO_SLASH_REG, '$1' while path.match MORE_THAN_TWO_SLASH_REG
        path = path.replace DOT_REG, '/' while path.match DOT_REG
        path = path.replace DOUBLE_DOT_REG, '/' while path.match DOUBLE_DOT_REG
        path

    exports.dirname = dirname
    exports.resolve = resolve
    exports.normalize = normalize


# **EventEmmiter**
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
            # copy `Array`
            listeners = @listeners(event).slice()
            if arguments.length > 1
                args = Array::slice arguments
                args.shift()
            for listener in listeners
                listener.apply @, args

    module.exports = EventEmmiter
 

# **Module**
__define 'module', (require, exports, module)->

    util = require 'util'
    EventEmmiter = require 'emmiter'
    path = require 'path'

    # **STATUS**
    #
    # The state of module's life.
    #
    # INIT: 0, The module is created  
    # FETCHING: 1, The `module.uri` is being fetched  
    # SAVED: 2,  The meta data has been saved to cachedMods  
    # LOADING: 3, The `module.dependencies` are being loaded  
    # LOADED: 4, The module are ready to execute  
    # EXECUTING: 5, The module is being executed  
    # EXECUTED: 6 The `module.exports` is available  
    STATUS = 
        INIT:       0
        FETCHING:   1
        SAVED:      2
        LOADING:    3
        LOADED:     4
        EXECUTING:  5
        EXECUTED:   6
    
    # Store the deps and factory of the loading module. When `onload` fire, save to the `Bodule.modules`  
    # refer as `id`
    moduleData = null

    # **class Module**
    class Module extends EventEmmiter
        # Static method or property, like `Module.get`
        @modules = {}
        # Get module by id. if there is already a module with `id`, save `deps` and `factory`
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
        # Define a open API for defining a module.
        @define: (id, deps, factory)->
            moduleData =
                deps: deps,
                factory: factory
        # Get the `module.exports`
        @require: (id)=>
            module = @modules[id]
            # If module.exports is not avalible, `use` it.
            module.exports or module.exports = @use module
        # Execute a module, return the `module.exports`
        @use: (module)->
            module.exec()
            module.exports
        # Save module's deps and factroy, and load deps.
        @save: (id, deps, factory)->
            module = @get id, deps, factory
            module.state = STATUS.SAVED
            module.loadDeps()

        # Instance method.
        #
        # Init a module
        constructor: (@id, @deps=[], @factory)->
            @deps = @deps.map (dep)=>
                dep = path.resolve @id, dep
                dep = path.normalize dep
            @exports = null
            # Set state to 0.
            @state = STATUS.INIT
            super
        # Run the module.
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
            # If this module is loading, just return
            if @state > STATUS.LOADING
                return
            @state = STATUS.LOADING

            for dep in @deps
                module = Module.get dep
                # when the dependence module is loaded, check all the deps of this module is loaded
                module.on 'loaded', @isDepsLoaded
                depModules.push module
            @depModules = depModules
            # Just do a check, Maybe all the deps are loaded
            @isDepsLoaded()

            for module in depModules
                # If the dep isn't fetched, fetch it  
                # if the dep is saved, start load it's deps
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
                # If all deps are loaded, fire `loaded` event.
                @emit 'loaded'
        fetch: ->
            if @state < STATUS.FETCHING
                util.loadScript @id, =>
                    # When the `onload` is called, save meta data of current module.
                    Module.save @id, moduleData.deps, moduleData.factory
                return
            @state = STATUS.FETCHING

    module.exports = Module


# **Config**
__define 'config', (require, exports, module)->
    path = require 'path'
    config =
        # `config.cwd` is the page location.  
        # if page's url is `http://coffeescript.org/documentation/docs/rewriter.html`  
        # `cwd` is `http://coffeescript.org/documentation/docs/`
        cwd: path.dirname location.href

    exports.config = (conf)->
        if arguments.length is 0
            config
        else
            for key, value of conf
                config[key] = value
            config


# **Bodule**
__define 'bodule', (require, exports, module)->

    Module = require 'module'
    util  = require 'util'
    path = require 'path'
    config = require 'config'

    # **Bodule API**
    Bodule =
        # **Bodule.use**
        use: (deps, factory)->
            # Treat use factory as a no id module  
            # Give it a random id, let it become a normal module.
            #
            # If cwd is `http://coffeescript.org/documentation/docs/` so  
            # id is `http://coffeescript.org/documentation/docs/_use_5`  
            # 5 is generate by `guid`.
            id = path.resolve config.config().cwd, "./_use_#{util.guid()}"
            id = path.normalize id
            module = Module.get id, deps, factory
            module.on 'loaded', ->
                # When loaded, just use it, open the runtime.
                Module.use module
            module.loadDeps()
        # **Bodule.define**
        define: (id, deps, factory)->
            Module.define id, deps, factory
        Module: Module

    module.exports = Bodule


# **Public API**
__use (require)->

    Bodule = require 'bodule'

    window.Bodule = Bodule
    window.define = ()->
        Bodule.define.apply(Bodule, arguments)
