define('basestone@0.0.1/src/util.js', ['./lang/lang'], function (require, exports, module) {
    
    require('./lang/lang')
    var
    util = {},
    __slice = Array.prototype.slice,
    __toString = Object.prototype.toString
    
    function extend(target, source) {
        for (var key in source) {
            target[key] = source[key]
        }
        return target
    }
    
    extend(util, {
        extend: extend,
        clone: function (obj) {
            if (typeof obj !== 'object') {
                return obj
            } else {
                if (util.isArray(obj)) {
                    return obj.slice()
                } else {
                    return util.extend({},
                    obj)
                }
            }
        },
        isArray: function (value) {
            if (typeof Array.isArray === 'function') {
                return Array.isArray(value);
            } else {
                return Object.prototype.toString.call(value) === '[object Array]';
            }
        },
        arrayify: function (o) {
            return __slice.call(o)
        }
    })
    
    exports.util = util
    
        
})