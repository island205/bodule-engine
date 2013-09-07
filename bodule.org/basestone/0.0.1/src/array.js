define('basestone@0.0.1/src/array', ['./emitter', './util'], function (require, exports, module) {
    
    var
    EventEmitter = require('./emitter').EventEmitter,
    util = require('./util').util
    
    function array(initArr) {
        initArr = initArr || []
    
        function array(arr) {
            if (arguments.length === 1) {
                if (util.isArray(arr)) {
                    initArr = arr
                    array.emit('reset', initArr)
                } else if (typeof arr === 'number') {
                    return initArr[arr]
                }
            } else {
                return util.clone(initArr)
            }
        }
    
        // Mutator method https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Array
        'pop push reverse shift sort splice unshit'.split(' ').forEach(function (method) {
            array[method] = function () {
                var
                args = util.arrayify(arguments),
                ret = initArr[method].apply(initArr, args)
                array.emit(method, args, initArr)
                array.emit('change', args, initArr)
                return ret
            }
        })
    
        // Accessor https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Array
        'concat join slice indexOf lastIndexOf'.split(' ').forEach(function (method) {
            array[method] = function () {
                return initArr[method].apply(initArr, arguments)
            }
        })
    
        // Iteration https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Array
        'forEach every some filter map reduce reduceRight'.split(' ').forEach(function (method) {
            array[method] = function () {
                return initArr[method].apply(initArr, arguments)
            }
        })
    
        util.extend(array, EventEmitter.prototype)
        return array
    
    }
    exports.array = array
    
        
})