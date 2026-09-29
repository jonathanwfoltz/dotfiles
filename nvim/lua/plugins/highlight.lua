local hipatterns = require('mini.hipatterns')
local hi_words = require('mini.extra').gen_highlighter.words
hipatterns.setup({
    highlighters = {
        todo = hi_words({ 'TODO', 'Todo', 'todo', 'TODO:', 'Todo:', 'todo:' }, 'MiniHipatternsTodo'),
        fixme = hi_words({ 'FIXME', 'FixMe', 'Fixme', 'fixme',
                           'FIXME:', 'FixMe:', 'Fixme:', 'fixme:' }, 'MiniHipatternsFixme'),
        hack = hi_words({ 'HACK', 'Hack', 'hack', 'HACK:', 'Hack:', 'hack:' }, 'MiniHipatternsHack'),
        note = hi_words({ 'NOTE', 'Note', 'note', 'NOTE:', 'Note:', 'note:' }, 'MiniHipatternsNote'),
        hex_color = hipatterns.gen_highlighter.hex_color(),
    },
})

