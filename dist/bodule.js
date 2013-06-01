(function() {
  var Bodule;

  Bodule = (function() {
    function Bodule(id, deps, factory) {
      var self, _ref;

      self = this;
      _ref = id.split('@'), this["package"] = _ref[0], this.version = _ref[1];
      this.version = this.version.split('/');
      this.path = this.version.slice(1, this.version.length);
      this.version = this.version[0];
      this.path = this.path.join('/');
      this.packageId = "" + this["package"] + "@" + this.version;
      this.id = id;
      this.deps = deps;
      this.deps = this.deps.map(function(dep) {
        if (dep.indexOf('@') === -1) {
          dep = Bodule.normalize(self.packageId + '/' + Bodule.dirname(self.path) + '/' + dep);
        }
        return dep;
      });
      this.factory = factory;
      this.exports = {};
      this.compiled = false;
      this.loaded = false;
      this.selfCompile = false;
    }

    Bodule._cache = {};

    Bodule._waitPool = {};

    Bodule._loading = {};

    Bodule.__guid = 0;

    Bodule.config = function(config) {
      this.config = config;
    };

    Bodule.require = function(id) {
      var bodule;

      bodule = this._cache[id];
      if (bodule) {
        if (bodule.compiled) {
          return bodule.exports;
        } else {
          bodule.compile();
          return bodule.exports;
        }
      } else {
        throw new Error("bodule " + id + " isn't exist");
      }
    };

    Bodule.define = function(id, deps, factory) {
      var bodule;

      console.log("define " + id);
      bodule = new Bodule(id, deps, factory);
      this._cache[id] = bodule;
      return bodule.load();
    };

    Bodule.use = function(mods, callback) {
      var bodule, id;

      id = this._guid();
      console.log("define " + id);
      bodule = new Bodule(id, mods, callback);
      bodule.selfCompile = true;
      this._cache[id] = bodule;
      return bodule.load();
    };

    Bodule._guid = function() {
      return "guid@" + (this.__guid++);
    };

    Bodule._load = function(bodule, parent) {
      var script, src, waitList, _base, _ref;

      waitList = (_ref = (_base = this._waitPool)[bodule]) != null ? _ref : _base[bodule] = [];
      if (waitList.indexOf(parent) === -1) {
        waitList.push(parent);
      }
      if (!!this._loading[bodule]) {
        return;
      }
      this._loading[bodule] = true;
      if (!Bodule._cache[bodule]) {
        script = document.createElement('script');
        src = this.config.host + '/' + bodule.replace('@', '/') + '.js';
        script.src = src;
        document.head.appendChild(script);
      }
    };

    Bodule._loaded = function(id) {
      var parent, waitList, _i, _len;

      waitList = this._waitPool[id];
      if (!waitList) {
        return;
      }
      for (_i = 0, _len = waitList.length; _i < _len; _i++) {
        parent = waitList[_i];
        Bodule._cache[parent].check();
      }
    };

    Bodule.normalize = function(path) {
      var toPath, top;

      path = path.replace(/\/\.\//g, '/');
      path = path.replace(/\/{2,}/g, '/');
      path = path.split('/');
      toPath = [];
      while (path.length > 0) {
        top = path.pop();
        if (top === '..') {
          path.pop();
        } else {
          toPath.unshift(top);
        }
      }
      return toPath.join('/');
    };

    Bodule.dirname = function(path) {
      path = path.split('/');
      path = path.slice(0, path.length - 1);
      return path.join('/');
    };

    Bodule.prototype.load = function() {
      var dep, deps, self, _i, _len;

      self = this;
      deps = this.deps.filter(function(dep) {
        return !Bodule._cache[dep] || !Bodule._cache[dep].loaded;
      });
      if (!deps.length) {
        this.loaded = true;
        Bodule._loaded(this.id);
      } else {
        for (_i = 0, _len = deps.length; _i < _len; _i++) {
          dep = deps[_i];
          Bodule._load(dep, self.id);
        }
      }
    };

    Bodule.prototype.check = function() {
      var deps;

      deps = this.deps.filter(function(dep) {
        return !Bodule._cache[dep] || !Bodule._cache[dep].loaded;
      });
      if (!deps.length && !this.loaded) {
        this.loaded = true;
        if (this.selfCompile) {
          this.compile();
        }
        return Bodule._loaded(this.id);
      }
    };

    Bodule.prototype.compile = function() {
      var exports, module, require, self,
        _this = this;

      console.log("compile module " + this.id);
      self = this;
      module = {};
      exports = module.exports = this.exports;
      require = function(id) {
        if (id.indexOf('@') === -1) {
          id = Bodule.normalize(_this.packageId + '/' + Bodule.dirname(_this.path) + '/' + id);
        }
        return Bodule.require(id);
      };
      this.factory(require, exports, module);
      this.exports = module.exports;
      this.compiled = true;
    };

    return Bodule;

  })();

  (function() {
    window.Bodule = Bodule;
    window.define = function() {
      return Bodule.define.apply(Bodule, arguments);
    };
    Bodule.config({
      host: 'http://localhost:8080'
    });
    define('bodule@0.1.0/d', ['basestone@0.0.1/src/basestone'], function(require, exports, module) {
      var basestone;

      basestone = require('basestone@0.0.1/src/basestone');
      exports.d = 'd';
      return exports.basestone = basestone;
    });
    define('bodule@0.1.0/c', ['./d', './e'], function(require, exports, module) {
      var d, e;

      d = require('./d');
      e = require('./e');
      exports.cfunc = function() {};
      exports.d = d;
      return exports.e = e;
    });
    return Bodule.use(['bodule@0.1.0/c'], function(require, exports, module) {
      var c;

      c = require('bodule@0.1.0/c');
      return console.log(c);
    });
  })();

}).call(this);
