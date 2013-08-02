(function() {
  var __define, __modules, __require, __use,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
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

  __define('util', function(require, exports, module) {
    var guid, head, i, loadScript;

    head = document.getElementsByTagName('head')[0];
    loadScript = function(id) {
      var node;

      node = document.createElement('script');
      node.type = 'text/javascript';
      node.async = true;
      node.src = "" + id + ".js";
      node.onload = function() {
        return head.removeChild(node);
      };
      return head.appendChild(node);
    };
    i = 0;
    guid = function() {
      return ++i;
    };
    exports.loadScript = loadScript;
    return exports.guid = guid;
  });

  __define('emmiter', function(require, exports, module) {
    var EventEmmiter;

    EventEmmiter = (function() {
      function EventEmmiter() {
        this.__listeners = {};
      }

      EventEmmiter.prototype.listeners = function(event) {
        var listeners;

        listeners = this.__listeners;
        return listeners[event] || (listeners[event] = []);
      };

      EventEmmiter.prototype.on = function(event, listener) {
        return this.listeners(event).push(listener);
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

  __define('module', function(require, exports, module) {
    var EventEmmiter, Module, STATUS, util;

    util = require('util');
    EventEmmiter = require('emmiter');
    STATUS = {
      INIT: 0,
      FETCHING: 1,
      SAVED: 2,
      LOADING: 3,
      LOADED: 4,
      EXECUTING: 5,
      EXECUTED: 6
    };
    Module = (function(_super) {
      __extends(Module, _super);

      Module.modules = {};

      Module.get = function(id, deps, factory) {
        module = this.modules[id];
        if (module) {
          module.deps = deps;
          module.factory = factory;
        } else {
          module = new Module(id, deps, factory);
        }
        return this.modules[id] = module;
      };

      Module.define = function(id, deps, factory) {
        module = this.get(id, deps, factory);
        module.state = STATUS.SAVED;
        module.loadDeps();
        return module;
      };

      Module.require = function(id) {
        module = Module.modules[id];
        return module.exports || (module.exports = Module.use(module));
      };

      Module.use = function(module) {
        exports = module.exports = {};
        module.factory(this.require, exports, module);
        return module.exports;
      };

      function Module(id, deps, factory) {
        this.id = id;
        this.deps = deps != null ? deps : [];
        this.factory = factory;
        this.isDepsLoaded = __bind(this.isDepsLoaded, this);
        this.exports = null;
        this.state = STATUS.INIT;
        Module.__super__.constructor.apply(this, arguments);
      }

      Module.prototype.loadDeps = function() {
        var dep, depModules, _i, _j, _len, _len1, _ref, _results;

        depModules = [];
        if (this.state > STATUS.LOADING) {
          return;
        }
        this.state = STATUS.LOADING;
        _ref = this.deps;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          dep = _ref[_i];
          module = Module.get(dep);
          module.on('loaded', this.isDepsLoaded);
          depModules.push(module);
        }
        this.depModules = depModules;
        this.isDepsLoaded();
        _results = [];
        for (_j = 0, _len1 = depModules.length; _j < _len1; _j++) {
          module = depModules[_j];
          if (module.state < STATUS.FETCHING) {
            _results.push(module.fetch());
          } else if (moudle.state === STATUS.SAVED) {
            _results.push(module.loadDeps());
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      Module.prototype.isDepsLoaded = function() {
        var loaded, _i, _len, _ref;

        loaded = true;
        _ref = this.depModules;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          module = _ref[_i];
          if (module.state < STATUS.LOADED) {
            loaded = false;
          }
        }
        if (loaded) {
          this.state = STATUS.LOADED;
          return this.emit('loaded');
        }
      };

      Module.prototype.fetch = function() {
        if (this.state < STATUS.FETCHING) {
          util.loadScript(this.id);
          return;
        }
        return this.state = STATUS.FETCHING;
      };

      return Module;

    }).call(this, EventEmmiter);
    return module.exports = Module;
  });

  __define('bodule', function(require, exports, module) {
    var Bodule, Module, util;

    Module = require('module');
    util = require('util');
    Bodule = {
      use: function(deps, factory) {
        module = Module.get('_use_' + util.guid(), deps, factory);
        module.on('loaded', function() {
          return Module.use(module);
        });
        return module.loadDeps();
      },
      define: function(id, deps, factory) {
        return Module.define(id, deps, factory);
      },
      Module: Module
    };
    return module.exports = Bodule;
  });

  __use(function(require) {
    var Bodule;

    Bodule = require('bodule');
    window.Bodule = Bodule;
    return window.define = function() {
      return Bodule.define.apply(Bodule, arguments);
    };
  });

}).call(this);
