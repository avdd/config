
c = get_config()

c.TerminalIPythonApp.display_banner = False
c.TerminalInteractiveShell.confirm_exit = False

#c.PromptManager.in_template = '[\#]> '
#c.PromptManager.in2_template = '.\D.  '
#c.PromptManager.out_template = '[\#]= '

from IPython.terminal import prompts
from pygments.token import Token

class Prompts(prompts.Prompts):
    def __init__(self, shell):
        self.shell = shell

    def in_prompt_tokens(self, cli=None):
        return [
            (Token.Prompt, '['),
            (Token.PromptNum, str(self.shell.execution_count)),
            (Token.Prompt, ']> '),
        ]

    def _width(self):
        return token_list_width(self.in_prompt_tokens())

    def continuation_prompt_tokens(self, cli=None, width=None):
        if width is None:
            width = self._width()
        return [
            (Token.Prompt, (' ' * (width - 5)) + '...: '),
        ]

    def rewrite_prompt_tokens(self):
        width = self._width()
        return [
            (Token.Prompt, ('-' * (width - 2)) + '> '),
        ]

    def out_prompt_tokens(self):
        return [
            (Token.OutPrompt, '['),
            (Token.OutPromptNum, str(self.shell.execution_count)),
            (Token.OutPrompt, ']> '),
]

c.TerminalInteractiveShell.prompts_class = Prompts
