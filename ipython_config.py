
c = get_config()

c.TerminalIPythonApp.display_banner = False
c.TerminalInteractiveShell.confirm_exit = False
c.PromptManager.in_template = '[\#]> '
c.PromptManager.in2_template = '.\D.  '
c.PromptManager.out_template = '[\#]= '

