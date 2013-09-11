# **bodule-engine** is a runtime, in which all of the wrapper `node` module are running.
# it's a part of  solution for packing `node` module to browser.
# it learn from [Sea.js](http://seajs.org/) a lot.


# **Seed runtime**

# This is a **private** CommonJS runtime for `bodule.js`.
# I use `node` module style to orgnize code.

# `__modules` for store private module like `util`,`path`, and so on.
modules = {}

# `__require` is used for getting module's API: `exports` property.
require = (id)->
    module = modules[id]
    module.exports or module.exports = use [], module.factory

# Define a module, save module in `__modules`. use `id` to refer them.
define = (id, deps, factory)->
    modules[id] =
        id: id
        deps: deps
        factory:factory

# `__use` to start a CommonJS runtime, or get a module's exports.
use = (deps, factory)->
    module = {}
    exports = module.exports = {}

    # In factory `call`, `this` is global
    factory require, exports, module
    module.exports


# **util**
define 'util', ['log'], (require, exports, module)->

    log = require 'log'

    head = document.getElementsByTagName('head')[0]
    
    # **util.loadScript**

    # Pass a `callback`, when module is loaded, saving the deps and factory of the module  
    # to `Bodule.modules[id]`.
    loadScript = (id) ->
        log "loadScript #{id}", 3
        node = document.createElement 'script'
        node.type = 'text/javascript'
        node.async = true
        
        # `id` is a absolute URI like `http://example.com/a`
        if not /\.js$/.test id
          id = "#{id}.js"
        node.src = id
        node.onload = ->
            head.removeChild node
             
        head.appendChild node
    
    # **util.cid**

    # `cid()` will return `1,2,3,4,5,6...`
    i = 0
    cid = ->
        ++i

    toString = Object::toString
    for type in ['Arguments', 'Function', 'String', 'Array', 'Number', 'Date', 'RegExp']
        do (type)->
            exports["is#{type}"] = (o)->
                toString.call(o) is "[object #{type}]"
    exports.loadScript = loadScript
    exports.cid = cid

# **debug**

define 'log', [], (require, exports, module)->
    debug = true
    level = 3
    module.exports = (args..., l = 0)->
        console.log.apply(console, args) if debug && l >= level


# **path**

# Deal with url path
define 'path', ['log'], (require, exports, module)->

    log = require 'log'
    
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
        log "resolve #{from} to #{to}", 0
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
        log "normalize #{path}", 0
        # JavaScript doesn't support `(?<!exp)`, so use group.
        path = path.replace MORE_THAN_TWO_SLASH_REG, '$1' while path.match MORE_THAN_TWO_SLASH_REG
        path = path.replace DOT_REG, '/' while path.match DOT_REG
        path = path.replace DOUBLE_DOT_REG, '/' while path.match DOUBLE_DOT_REG
        path

    exports.dirname = dirname
    exports.resolve = resolve
    exports.normalize = normalize


# **EventEmmiter**
define 'emmiter', [], (require, exports, module)->

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
define 'module', ['util', 'emmiter', 'path', 'config', 'log'], (require, exports, module)->

    util = require 'util'
    EventEmmiter = require 'emmiter'
    path = require 'path'
    config = require 'config'
    log = require 'log'

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
                module
            else
                log "init module #{id}", 3
                module = new Module id, deps, factory
                @modules[id] = module
        # Define a open API for defining a module.
        @define: (id, deps, factory)->
            id = @resolve id
            @save id, deps, factory
        # Get the `module.exports`
        @require: (id)=>
            log "require module #{id}", 3
            module = @modules[id]
            # If module.exports is not avalible, `use` it.
            module.exports or module.exports = @use module
        # Execute a module, return the `module.exports`
        @use: (module)->
            log "use module #{module.id}", 3
            module.exec()
            module.exports
        # Save module's deps and factroy, and load deps.
        @save: (id, deps, factory)->
            module = @get id
            log "save module #{id}", 3
            module.deps = deps.map (dep)=>
                @resolve dep
            module.factory = factory
            module.state = STATUS.SAVED
            module.loadDeps()
        @resolve: (id)->
            conf = config.config()
            if not /^http:\/\/|^\.|^\//.test(id)
                if id.indexOf('@') == -1
                    id = "#{id}/#{conf.bodule_modules.dependencies[id]}/#{id}"
                else
                    [id, version] = id.split('@')
                    
                    # backbone@1.0.0
                    if version.indexOf('/') > -1
                        id = "#{id}/#{version}"
                    # backbone@1.0.0/backbone.js
                    else
                        id = "#{id}/#{version}/#{id}"

                conf = conf.bodule_modules
            id = conf.path + id
            id = path.resolve conf.cwd, id
            id = path.normalize id
            if not /\.js$/.test id
                id = "#{id}.js"
            id
        # Instance method.
        #
        # Init a module
        constructor: (@id, @deps=[], @factory)->
            @deps = @deps.map (dep)=>
                @resolve dep
            @exports = null
            # Set state to 0.
            @state = STATUS.INIT
            super
        # Run the module.
        exec: ->
            # Factory is Function
            if util.isFunction @factory
                __require = (id)=>
                    id = @resolve id
                    Module.require id
                __module = {}
                __exports = __module.exports = {}
                @factory(__require, __exports, __module)
                @exports = __module.exports

            # `define(id, someThingNotFunction)`
            else
                @exports = @factory
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
                else if module.state is STATUS.SAVED
                    module.loadDeps()
        isDepsLoaded: =>
            loaded = true
            for module in @depModules
                if module.state < STATUS.LOADED
                    loaded = false
            if loaded
                @state = STATUS.LOADED
                # If all deps are loaded, fire `loaded` event.
                log "module #{@id} is loaded", 2
                @emit 'loaded'
        fetch: ()->
            log "fetch module #{@id}", 3
            if @state < STATUS.FETCHING
                util.loadScript @id
                @state = STATUS.FETCHING
                return
        resolve: (id)->
            log "module #{@id} resolve dep #{id}", 2
            if not /^http:\/\/|^\.|^\//.test(id)
                conf = config.config()
                if id.indexOf('@') == -1
                    id = "#{id}/#{conf.bodule_modules.dependencies[id]}/#{id}"
                else
                    [id, version] = id.split('@')
                    id = "#{id}/#{version}/#{id}"
                boduleModules = conf.bodule_modules
                id = boduleModules.cwd + boduleModules.path + id
            else
                id = path.resolve @id, id
            id = path.normalize id
            if not /\.js$/.test id
                id = "#{id}.js"
            id

    module.exports = Module


# **Config**
define 'config', ['path', 'util'], (require, exports, module)->
    path = require 'path'
    util = require 'util'
    config =
        # `config.cwd` is the page location.  
        # if page's url is `http://coffeescript.org/documentation/docs/rewriter.html`  
        # `cwd` is `http://coffeescript.org/documentation/docs/`
        cwd: path.dirname location.href
        path: ''
        bodule_modules:
            cwd: 'http://bodule.org/',
            path: ''

    exports.config = (conf)->
        if arguments.length is 0
            config
        else
            for key, value of conf
                if util.isString(value) or util.isNumber(value)
                    config[key] = value 
                else if util.isArray value
                    config[key].concat(value)
                else
                    for k, v of value
                        config[key][k] = v
            config


# **Bodule**
define 'bodule', ['module', 'util', 'path', 'config'], (require, exports, module)->

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
            # 5 is generate by `cid`.
            if util.isString deps
                id = deps
                deps = []
                factory = null
                noCallback = true
            else
                id = "./_use_#{util.cid()}"
            id = Module.resolve id
            mod = Module.get id, deps, factory
            mod.on 'loaded', ->
                # When loaded, just use it, open the runtime.
                Module.use mod
            if noCallback
                mod.fetch()
            else
                mod.loadDeps()
        # **Bodule.define**
        define: (id, deps, factory)->
            # `define(id, factory)`
            if util.isFunction deps
                factory = deps
                deps = []
            # `define(id, somethingElseNotFunction)`
            else if typeof factory is 'undefined'
                deps = []
                factory = deps
            Module.define id, deps, factory
        package: (conf)->
            config.config(conf)
        Module: Module

    module.exports = Bodule


# **Public API**
use ['bodule'], (require)->

    Bodule = require 'bodule'

    window.Bodule = Bodule
    window.define = ()->
        Bodule.define.apply(Bodule, arguments)
