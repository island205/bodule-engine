# bodule-engine
# =============
# 
# **bodule-engine** is a runtime, in which all of the wrapper `node` module are running.
# it's a part of  solution for packing `node` module to browser.

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

 
__define 'state', (require, exports, module)->
    class State
    module.exports = State
    
 
__define 'module', (require, exports, module)->
    class Module extends State
    module.exports = Module
