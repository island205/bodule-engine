module.exports = (grunt) ->
    grunt.initConfig
        watch:
            scripts:
                files:['src/*.coffee'],
                tasks:['coffee', 'copy']
        coffee:
            compile:
                options:
                    join: true
                files:
                    'dist/bodule.js': ['src/*.coffee']
                    'bodule.org/bodule.js': ['src/*.coffee']
        copy:
          bodule:
            files:
              '../bodule-cloud/public/bodule.js': 'dist/bodule.js'

    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-copy'

    grunt.registerTask 'default', ['coffee', 'copy', 'watch']
