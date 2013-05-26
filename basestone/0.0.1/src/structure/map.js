define('basestone@0.0.1/src/structure/map.js', ['../util'], function (require, exports, module) {
    
    var
    util = require('../util').util
    
    function Map(iterable) {
        iterable = iterable || []
        this._keys = []
        this._vals = []
        iterable.forEach(function (item) {
            this.set(item[0], item[1])
        }.bind(this))
    }
    
    exports.Map = Map
    
    util.extend(Map.prototype, {
        get: function (key) {
            var i
            i = this._keys.indexOf(key)
            return i < 0 ? undefined: this._vals[i]
        },
        has: function (key) {
            return this._keys.indexOf(key) >= 0
        },
        set: function (key, val) {
            var keys, i
            keys = this._keys
            i = this._keys.indexOf(key)
            if (i < 0) {
                i = keys.length
            }
            keys[i] = key
            this._vals[i] = val
        },
        remove: function (key) {
            var keys, i
            keys = this._keys
            i = this._keys.indexOf(key)
            if (i < 0) {
                return false
            }
            keys.splice(i, 1)
            this._vals.splice(i, 1)
            return true
        },
        items: function (iterator) {
            var keys = this._keys
            for (var i = 0; i < keys.length; i++) {
                iterator(keys[i], this._vals[i])
            }
        },
        keys: function (iterator) {
            var keys = this._keys
            if (typeof iterator === 'undefined') {
                return util.clone(keys)
            }
            for (var i = 0; i < keys.length; i++) {
                iterator(keys[i])
            }
        },
        values: function (iterator) {
            if (typeof iterator === 'undefined') {
                return util.clone(this._vals)
            }
            for (var i = 0; i < this._keys.length; i++) {
                iterator(this._vals[i])
            }
        }
    })
    
        
})