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
    var cid, head, i, loadScript, log, toString, type, _fn, _i, _len, _ref;
    log = require('log');
    head = document.getElementsByTagName('head')[0];
    loadScript = function(id) {
      var node;
      log("loadScript " + id);
      node = document.createElement('script');
      node.type = 'text/javascript';
      node.async = true;
      if (!/\.js$/.test(id)) {
        id = "" + id + ".js";
      }
      node.src = id;
      node.onload = function() {
        return head.removeChild(node);
      };
      return head.appendChild(node);
    };
    i = 0;
    cid = function() {
      return ++i;
    };
    toString = Object.prototype.toString;
    _ref = ['Arguments', 'Function', 'String', 'Array', 'Number', 'Date', 'RegExp'];
    _fn = function(type) {
      return exports["is" + type] = function(o) {
        return toString.call(o) === ("[object " + type + "]");
      };
    };
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      type = _ref[_i];
      _fn(type);
    }
    exports.loadScript = loadScript;
    return exports.cid = cid;
  });

  __define('log', function(require, exports, module) {
    var debug;
    debug = true;
    return module.exports = function() {
      if (debug) {
        return console.log.apply(console, arguments);
      }
    };
  });

  __define('path', function(require, exports, module) {
    var DIRNAME_REG, DOT_REG, DOUBLE_DOT_REG, MORE_THAN_TWO_SLASH_REG, ROOT_DIR_REG, dirname, log, normalize, resolve;
    log = require('log');
    DIRNAME_REG = /[^?#]*\//;
    ROOT_DIR_REG = /^.*?\/\/.*?\//;
    MORE_THAN_TWO_SLASH_REG = /([^:]\/)(\/{1,})/;
    DOT_REG = /\/\.\//;
    DOUBLE_DOT_REG = /\/[^/]+\/\.\.\//;
    dirname = function(path) {
      return path.match(DIRNAME_REG)[0];
    };
    resolve = function(from, to) {
      var fisrt, match, path;
      log("resolve " + from + " to " + to);
      fisrt = to.charAt(0);
      if (fisrt === '.') {
        path = dirname(from) + to;
      }
      if (fisrt === '/') {
        match = from.match(ROOT_DIR_REG);
        path = match[0] + to.substring(0);
      }
      return path;
    };
    normalize = function(path) {
      log("normalize " + path);
      while (path.match(MORE_THAN_TWO_SLASH_REG)) {
        path = path.replace(MORE_THAN_TWO_SLASH_REG, '$1');
      }
      while (path.match(DOT_REG)) {
        path = path.replace(DOT_REG, '/');
      }
      while (path.match(DOUBLE_DOT_REG)) {
        path = path.replace(DOUBLE_DOT_REG, '/');
      }
      return path;
    };
    exports.dirname = dirname;
    exports.resolve = resolve;
    return exports.normalize = normalize;
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
    var EventEmmiter, Module, STATUS, config, log, moduleData, path, util;
    util = require('util');
    EventEmmiter = require('emmiter');
    path = require('path');
    config = require('config');
    log = require('log');
    STATUS = {
      INIT: 0,
      FETCHING: 1,
      SAVED: 2,
      LOADING: 3,
      LOADED: 4,
      EXECUTING: 5,
      EXECUTED: 6
    };
    moduleData = null;
    Module = (function(_super) {
      __extends(Module, _super);

      Module.modules = {};

      Module.get = function(id, deps, factory) {
        module = this.modules[id];
        if (module) {
          return module;
        } else {
          log("init module " + id);
          module = new Module(id, deps, factory);
          return this.modules[id] = module;
        }
      };

      Module.define = function(id, deps, factory) {
        id = this.resolve(id);
        return this.save(id, deps, factory);
      };

      Module.require = function(id) {
        log("require module " + id);
        module = Module.modules[id];
        return module.exports || (module.exports = Module.use(module));
      };

      Module.use = function(module) {
        log("use module " + module.id);
        module.exec();
        return module.exports;
      };

      Module.save = function(id, deps, factory) {
        var _this = this;
        module = this.get(id);
        log("save module " + id);
        module.deps = deps.map(function(dep) {
          return _this.resolve(dep);
        });
        module.factory = factory;
        module.state = STATUS.SAVED;
        return module.loadDeps();
      };

      Module.resolve = function(id) {
        var conf, version, _ref;
        conf = config.config();
        if (!/^http:\/\/|^\.|^\//.test(id)) {
          if (id.indexOf('@') === -1) {
            id = "" + id + "/" + conf.bodule_modules.dependencies[id] + "/" + id;
          } else {
            _ref = id.split('@'), id = _ref[0], version = _ref[1];
            id = "" + id + "/" + version + "/" + id;
          }
          conf = conf.bodule_modules;
        }
        id = conf.path + id;
        id = path.resolve(conf.cwd, id);
        id = path.normalize(id);
        if (!/\.js$/.test(id)) {
          id = "" + id + ".js";
        }
        return id;
      };

      function Module(id, deps, factory) {
        var _this = this;
        this.id = id;
        this.deps = deps != null ? deps : [];
        this.factory = factory;
        this.isDepsLoaded = __bind(this.isDepsLoaded, this);
        this.deps = this.deps.map(function(dep) {
          return _this.resolve(dep);
        });
        this.exports = null;
        this.state = STATUS.INIT;
        Module.__super__.constructor.apply(this, arguments);
      }

      Module.prototype.exec = function() {
        var __exports, __module,
          _this = this;
        if (util.isFunction(this.factory)) {
          __require = function(id) {
            id = _this.resolve(id);
            return Module.require(id);
          };
          __module = {};
          __exports = __module.exports = {};
          this.factory(__require, __exports, __module);
          return this.exports = __module.exports;
        } else {
          return this.exports = this.factory;
        }
      };

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
          log("module " + this.id + " is loaded");
          return this.emit('loaded');
        }
      };

      Module.prototype.fetch = function() {
        log("fetch module " + this.id);
        if (this.state < STATUS.FETCHING) {
          util.loadScript(this.id);
          this.state = STATUS.FETCHING;
        }
      };

      Module.prototype.resolve = function(id) {
        var boduleModules, conf, version, _ref;
        log("module " + this.id + " resolve dep " + id);
        if (!/^http:\/\/|^\.|^\//.test(id)) {
          conf = config.config();
          if (id.indexOf('@') === -1) {
            id = "" + id + "/" + conf.bodule_modules.dependencies[id] + "/" + id;
          } else {
            _ref = id.split('@'), id = _ref[0], version = _ref[1];
            id = "" + id + "/" + version + "/" + id;
          }
          boduleModules = conf.bodule_modules;
          id = boduleModules.cwd + boduleModules.path + id;
        } else {
          id = path.resolve(this.id, id);
        }
        id = path.normalize(id);
        if (!/\.js$/.test(id)) {
          id = "" + id + ".js";
        }
        return id;
      };

      return Module;

    }).call(this, EventEmmiter);
    return module.exports = Module;
  });

  __define('config', function(require, exports, module) {
    var config, path, util;
    path = require('path');
    util = require('util');
    config = {
      cwd: path.dirname(location.href),
      path: '',
      bodule_modules: {
        cwd: 'http://bodule.org/',
        path: ''
      }
    };
    return exports.config = function(conf) {
      var k, key, v, value;
      if (arguments.length === 0) {
        return config;
      } else {
        for (key in conf) {
          value = conf[key];
          if (util.isString(value) || util.isNumber(value)) {
            config[key] = value;
          } else if (util.isArray(value)) {
            config[key].concat(value);
          } else {
            for (k in value) {
              v = value[k];
              config[key][k] = v;
            }
          }
        }
        return config;
      }
    };
  });

  __define('bodule', function(require, exports, module) {
    var Bodule, Module, config, path, util;
    Module = require('module');
    util = require('util');
    path = require('path');
    config = require('config');
    Bodule = {
      use: function(deps, factory) {
        var id, mod, noCallback;
        if (util.isString(deps)) {
          id = deps;
          deps = [];
          factory = null;
          noCallback = true;
        } else {
          id = "./_use_" + (util.cid());
        }
        id = Module.resolve(id);
        mod = Module.get(id, deps, factory);
        mod.on('loaded', function() {
          return Module.use(mod);
        });
        if (noCallback) {
          return mod.fetch();
        } else {
          return mod.loadDeps();
        }
      },
      define: function(id, deps, factory) {
        if (util.isFunction(deps)) {
          factory = deps;
          deps = [];
        } else if (typeof factory === 'undefined') {
          deps = [];
          factory = deps;
        }
        return Module.define(id, deps, factory);
      },
      "package": function(conf) {
        return config.config(conf);
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
