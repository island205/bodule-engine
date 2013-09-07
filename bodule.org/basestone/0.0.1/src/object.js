define('basestone@0.0.1/src/object', ['./emitter', './util'], function (require, exports, module) {
    
    var
    EventEmitter = require('./emitter').EventEmitter,
    util = require('./util').util
    
    function object(obj) {
        obj = obj || {}
    
        function object(key, value) {
    
            var
            type, len = util.arrayify(arguments).length
            type = typeof key
    
            // return `obj` without argument
            // get value by `key` form obj when arguments's length is `1`
            // and the type if `key` is `tring`.
            // if type is `object`, extend `key` to `obj`
            // otherwise set `obj` with `key` `value`
            if (len === 0) {
                return util.clone(obj)
            } else if (len === 1) {
                if (type === 'string') {
                    return obj[key]
                } else {
                    // util.extend(obj, key)
                    Object.keys(key).forEach(function (k) {
                        object(k, key[k])
                    })
                }
            } else {
                obj[key] = value
                object.emit('change:' + key, value)
                object.emit('change', obj)
            }
        }
    
        'keys'.split(' ').forEach(function (method) {
            object[method] = function () {
                return Object[method].apply(Object, [obj])
            }
        })
    
        util.extend(object, EventEmitter.prototype)
        return object
    }
    exports.object = object
    
        
})