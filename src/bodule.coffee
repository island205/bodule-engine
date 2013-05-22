class Bodule
    constructor: (id, parent) ->
        @id = id
        @parent = parent
        @children = []
        @exports = {}
        @loaded = false

        parent?.children?.push @
        return
    load: ->
        ###
        Sync or Async load, base env
        ###
    compile: ->
