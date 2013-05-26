define('basestone@0.0.1/src/set.js', ['./emitter', './structure/set', './util'], function (require, exports, module) {
    
    var
    EventEmitter = require('./emitter').EventEmitter,
    Set = require('./structure/set').Set,
    util = require('./util').util
    
    function set(iterable) {
        var
        st = new Set(iterable)
    
        function set(key) {
            var
            len, iterable
            len = util.arrayify(arguments).length
    
            if (len === 0) {
                return st.values()
            } else {
                if (util.isArray(key)) {
                    iterable = key
                    iterable.forEach(function (item) {
                        set.add(item)
                    })
                } else {
                    set.add(key)
                }
            }
        }
        
        // Metator method
        'add remove'.split(' ').forEach(function (method) {
            set[method] = function (value) {
                var
                ret
                ret = st[method].apply(st, arguments)
                set.emit(method, value)
                set.emit('change', value)
                return ret
            }
        })
    
        // Accessor & Iterator method
        'has values'.split(' ').forEach(function (method) {
            set[method] = function () {
                return st[method].apply(st, arguments)
            }
        })
    
        util.extend(set, EventEmitter.prototype)
    
        return set
    }
    
    exports.set = set
        
})