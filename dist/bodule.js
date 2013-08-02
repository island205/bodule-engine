(function() {
  var __define, __modules, __require, __use,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  __modules = {};

  __require = function(id) {
    var module;

    module = __modules[id];
    return module.exports || (module.exports = __use(module.factory));
  };

  __define = function(id, factory) {
    return __modules[id] = {
      id: id,
      factory: factory
    };
  };

  __use = function(factory) {
    var exports, module;

    module = {};
    exports = module.exports = {};
    factory(__require, exports, module);
    return module.exports;
  };

  __define('emmiter', function(require, exports, module) {
    var EventEmmiter;

    EventEmmiter = (function() {
      function EventEmmiter() {
        this.__listeners = {};
      }

      EventEmmiter.prototype.listeners = function(event) {
        var listeners;

        listeners = this.listeners;
        return listeners[event] || (listeners[event] = []);
      };

      EventEmmiter.prototype.once = function(event, listener) {
        var once,
          _this = this;

        once = function() {
          _this.off(event, listener);
          return listener.apply(_this, arguments);
        };
        once.__listener = listener;
        return this.on(event, once);
      };

      EventEmmiter.prototype.on = function(event, listener) {
        return this.listeners(event).push(listener);
      };

      EventEmmiter.prototype.off = function(event, listener) {
        var index, lis, listeners, _i, _len;

        index = -1;
        listeners = this.listeners(event);
        for (_i = 0, _len = listeners.length; _i < _len; _i++) {
          lis = listeners[_i];
          if (lis === listener || lis.listener === listener) {
            index = i;
          }
        }
        if (index !== -1) {
          return listeners.splice(index, 1);
        }
      };

      EventEmmiter.prototype.emit = function(event) {
        var args, listener, listeners, _i, _len, _results;

        args = [];
        listeners = this.listeners(event).slice();
        if (arguments.length > 1) {
          args = Array.prototype.slice(arguments);
          args.shift();
        }
        _results = [];
        for (_i = 0, _len = listeners.length; _i < _len; _i++) {
          listener = listeners[_i];
          _results.push(listener.apply(this, args));
        }
        return _results;
      };

      return EventEmmiter;

    })();
    return module.exports = EventEmmiter;
  });

  __define('state', function(require, exports, module) {
    var EventEmmiter, State, _ref;

    EventEmmiter = require('emmiter');
    State = (function(_super) {
      __extends(State, _super);

      function State() {
        _ref = State.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      return State;

    })(EventEmmiter);
    return module.exports = State;
  });

  __define('module', function(require, exports, module) {
    var Module, _ref;

    Module = (function(_super) {
      __extends(Module, _super);

      function Module() {
        _ref = Module.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      return Module;

    })(State);
    return module.exports = Module;
  });

}).call(this);
