
c = get_config()

c.InteractiveShell.colors = 'linux'
c.TerminalInteractiveShell.highlighting_style = 'monokai'

c.TerminalIPythonApp.display_banner = False
c.TerminalInteractiveShell.confirm_exit = False

from IPython.terminal import prompts
from pygments.token import Token

c.TerminalInteractiveShell.display_completions = 'readlinelike'


class Prompts(prompts.Prompts):
    def in_prompt_tokens(self, cli=None):
        return [
            (Token.Prompt, '['),
            (Token.PromptNum, str(self.shell.execution_count)),
            (Token.Prompt, ']> '),
        ]

    def out_prompt_tokens(self):
        return [
            (Token.OutPrompt, '['),
            (Token.OutPromptNum, str(self.shell.execution_count)),
            (Token.OutPrompt, ']> '),
        ]


c.TerminalInteractiveShell.prompts_class = Prompts
