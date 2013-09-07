define('basestone@0.0.1/src/emitter', [], function (require, exports, module) {
    
    // exports.EventEmitter = require('events').EventEmitter
    var
    __slice = Array.prototype.slice
    
    function EventEmitter() {}
    
    var proto = EventEmitter.prototype
    
    proto.listeners = function (event) {
        var
        listeners
        listeners = this.__listeners = this.__listeners || {}
        listeners.__maxListeners = listeners.__maxListeners || 10
        listeners[event] = listeners[event] || []
        return listeners[event]
    }
    proto.addEventListener = function (event, listener) {
        var
        listeners = this.listeners(event)
        if (listeners.length !== 0 && listeners.length >= this.__listeners.__maxListeners) {
            throw new Error('Listener can\'t more than ' + this.listeners.__maxListeners)
        }
        listeners.push(listener)
        this.emit('newListener')
    }
    
    proto.on = proto.addEventListener
    
    proto.once = function (event, listener) {
        var
        once
    
        once = function () {
            this.removeListener(event, listener)
            listener.apply(this, arguments)
        }.bind(this)
    
        once.__listener = listener
        this.addEventListener(event, once)
    }
    
    proto.removeListener = function (event, listener) {
        var
        listeners = this.listeners(event),
        i,
        len,
        index = - 1
    
        for (i = 0, len = listeners.length; i < len; i++) {
            if (listener === listeners[i] || listener === listeners[i].__listener) {
                index = i
                break
            }
        }
        if (index !== - 1) {
            listeners.splice(index, 1)
        }
    }
    
    proto.removeAllListeners = function (event) {
    
        if (typeof event === 'undefined') {
            this.__listeners = null
        } else {
            if (typeof this.__listeners[event] !== 'undefined') {
                this.__listeners[event] = null
            }
        }
    }
    
    proto.setMaxListeners = function (n) {
        this.__listeners.__maxListeners = n
    }
    
    proto.emit = function (event) {
        var
        args, listeners, i, len
    
        listeners = this.listeners(event).slice()
        args = []
    
        if (arguments.length > 1) {
            args = __slice.call(arguments)
            args.shift()
        }
    
        for (i = 0, len = listeners.length; i < len; i++) {
            listeners[i].apply(this, args)
        }
    }
    
    exports.EventEmitter = EventEmitter
        
})