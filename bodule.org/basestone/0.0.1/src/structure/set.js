define('basestone@0.0.1/src/structure/set', ['../util', './map'], function (require, exports, module) {
    
    var
    util = require('../util').util,
    Map = require('./map').Map
    
    function Set(iterable) {
        iterable = iterable || []
        this._map = new Map()
        iterable.forEach(function (item) {
            this.add(item)
        }.bind(this))
    }
    
    exports.Set = Set
    
    util.extend(Set.prototype, {
        add: function (key) {
            this._map.set(key, true)
        },
        has: function (key) {
            return this._map.has(key)
        },
        remove: function (key) {
            return this._map.remove(key)
        },
        values: function () {
            return this._map.keys.apply(this._map, arguments)
        }
    })
    
        
})