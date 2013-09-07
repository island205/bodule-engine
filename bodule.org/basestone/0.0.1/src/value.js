define('basestone@0.0.1/src/value', ['./emitter', './util'], function (require, exports, module) {
    
    var
    EventEmitter = require('./emitter').EventEmitter,
    util = require('./util').util
    
    function value(initVal) {
        // val = val || undefined
        function value(val) {
            if (typeof val === 'undefined') {
                return initVal
            } else {
                initVal = val
                value.emit('change', initVal)
            }
        }
        util.extend(value, EventEmitter.prototype)
        return value
    }
    exports.value = value
        
})