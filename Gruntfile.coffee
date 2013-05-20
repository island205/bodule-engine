module.exports = (grunt) ->
    grunt.initConfig
        watch:
            task: 'coffee'
        coffee:
            compileJoined:
                'dist/bodule.js': ['src/*.coffee']

    grunt.loadNpmTasks 'grunt-contrib-coffee'

    grunt.registerTask 'default', 'watch'
