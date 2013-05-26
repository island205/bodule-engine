define('basestone@0.0.1/src/map.js', ['./emitter', './structure/map', './util'], function (require, exports, module) {
    
    var
    EventEmitter = require('./emitter').EventEmitter,
    Map = require('./structure/map').Map,
    util = require('./util').util
    
    function toJSON(mp) {
        var
        json = []
        mp.keys(function (key) {
            json.push([key, mp.get(key)])
        })
    
        return json
    }
    
    function map(iterable) {
        var
        mp = new Map(iterable)
        function map(key, value) {
            var
            len = util.arrayify(arguments).length,
            iterable
    
            if (len === 0) {
    
                return toJSON(mp)
    
            } else if (len === 1) {
                if (util.isArray(key)) {
                    iterable = key
                    iterable.forEach(function (item) {
                        var key, value
                        key = item[0]
                        value = item[1]
                        map.set(key, value)
                    })
                } else {
                    return map.get(key)
                }
            } else {
                map.set(key, value)
            }
        }
        
        // Motator method
        'set remove'.split(' ').forEach(function (method) {
            map[method] = function (key, value) {
                var
                ret = mp[method].apply(mp, arguments)
                if (method === 'remove') {
                    map.emit('remove', key)
                } else {
                    map.emit('change:' + key, value)
                    map.emit('change', key, value)
                }
                return ret
            }
        })
    
        // Accessor & Iterator method
        'get has items keys values'.split(' ').forEach(function (method) {
            map[method] = function () {
                return mp[method].apply(mp, arguments)
            }
        })
    
        util.extend(map, EventEmitter.prototype)
        return map
    }
    
    exports.map = map
    
        
})