
cmdtable = {}

def cmd(f):
    name = f.__name__.replace('_', '-')
    cmdtable[name] = (f, [], f.__doc__)


@cmd
def hold(ui, repo, **opts):
    'stash'
    import datetime
    import time
    from mercurial import commands, hg
    cx = repo[None]
    now = time.strftime('%Y%m%d%H%M%S')
    fn = repo.join('hold-%s-%s' % (now, cx.p1()))
    open(fn, 'wb').writelines(cx.diff())
    ui.status('patch written to %s\n' % fn)
    #;hold = !$HG di -S > .hg/hold-$($HG parents --template '{node|short}')-$(date +%Y%m%d%H%M%S)


@cmd
def shell(ui, repo, **opts):
    import mercurial
    from mercurial import demandimport
    demandimport.disable()

    objs = {
        'mercurial': mercurial,
        'repo': repo,
        'ui': ui,
    }
    banner = 'repo: %s\nsource: %s' % (repo.root, mercurial.__path__[0])
    try:
        from IPython.config.loader import Config
        from IPython.frontend.terminal.embed import InteractiveShellEmbed as Sh
    except:
        import code, traceback
        traceback.print_exc()
        return code.interact(banner=banner, local=objs)
    else:
        cfg = Config()
        cfg.TerminalInteractiveShell.confirm_exit = False
        pc = cfg.PromptManager
        pc.in_template = '[\#]> '
        pc.in2_template = '.\D.  '
        pc.out_template = '[\#]= '
        return Sh(user_ns=objs, config=cfg, banner1=banner)()


@cmd
def prompt(ui, repo, **opts):
    cx = repo[None]
    parents = cx.parents()
    p0 = parents[0]
    node = p0.node()
    branch = cx.branch()
    heads = repo.branchheads(branch)
    tags = sum([p.tags() for p in parents], [])
    bookmarks = sum([p.bookmarks() for p in parents], [])
    bookmark = repo._bookmarkcurrent
    if bookmark in bookmarks:
        bookmarks.remove(bookmark)
    else:
        bookmark = None

    if len(parents) > 1:
        headstate = '(merge)'
    elif branch != p0.branch():
        headstate = '(new branch)'
    elif (p0.extra().get('close') and
          node in repo.branchheads(branch, closed=True)):
        headstate = '(head closed)'
    elif node not in heads:
        headstate = '(new head)'
    else:
        headstate = '(head)'

    new = [0] * len(repo)
    cl = repo.changelog
    hrevs = [cl.rev(x) for x in heads]
    prevs = [p.rev() for p in parents]
    for i in hrevs:
        new[i] = 1
    for i in cl.ancestors(hrevs):
        new[i] = 1
    for i in prevs:
        if i >= 0:
            new[i] = 0
    for i in cl.ancestors(prevs):
        new[i] = 0

    new = sum(new)
    if not new:
        upstate = ''
    elif node not in heads:
        upstate = 'new:%d' % new
    else:
        upstate = 'new:%d heads:%d' % (new, len(heads))

    # working status
    mods, adds, rems, dels, unk = repo.status(unknown=True)[:5]

    # merge conflicts
    from mercurial import merge
    ms = merge.mergestate(repo)
    unr = [f for f in ms if ms[f] == 'u']

    # subrepos
    sub = [s for s in cx.substate if cx.sub(s).dirty()]


    pad = [False]
    def wr(m, l=''):
        if pad[0]:
            ui.write(' ')
        pad[0] = True
        return ui.write(m, label=l)


    ps = [('%d:%s' % (p.rev(), p)) for p in parents]
    wr(','.join(ps), 'log.changeset')
    wr(branch, 'log.branch')
    if bookmark:
        wr(bookmark, 'bookmarks.current')
    if bookmarks:
        wr(','.join(bookmarks), 'log.bookmark')
    if tags:
        wr(','.join(tags), 'log.tag')
    if mods:
        wr('%dM' % len(mods), 'status.modified')
    if adds:
        wr('%dA' % len(adds), 'status.added')
    if rems:
        wr('%dR' % len(rems), 'status.removed')
    if dels:
        wr('%d!' % len(dels), 'status.deleted')
    if unk:
        wr('%d?' % len(unk), 'status.unknown')
    if unr:
        wr('%d>' % len(unr), 'resolve.unresolved')
    if sub:
        wr('/M', 'status.modified')

    wr(headstate, 'log.changeset')
    wr(upstate)
    wr('\n')


# unused:
@cmd
def feature_start(ui, repo, tag, **opts):
    '''
    shortcut to start a feature:

    hg pull
    hg update trunk
    hg bookmark TAG
    '''


@cmd
def feature_push(ui, repo, **opts):
    '''
    pull, rebase and push

    hg pull -B trunk --rebase

    # fix any merge conflicts from rebase
    # hg commit -m 'fix merge conflict'

    # push new work
    hg push -B TAG -f
    '''


@cmd
def feature_complete(ui, repo, **opts):
    '''
    complete the feature

    # pull again to be sure
    hg pull -B trunk --rebase

    # because the merging is done via rebase,
    # a merge is not required at this stage
    # just reset trunk
    hg bookmark -f trunk
    hg bookmark -d TAG
    hg push -B trunk -B TAG -f

    # merge trunk to release
    hg update -C release
    hg merge trunk

    # fix any merge conflicts and commit merge
    hg ci -m merge

    # push release for testing
    hg push -r release -f
    '''


# hooks
HOOKDEBUG = HOOKLOG = 0


def uisetup__disabled(ui):
    from mercurial import extensions, hook
    import sys; sys.excepthook = None
    extensions.wrapfunction(hook, 'hook', wraphook)
    global HOOKDEBUG, HOOKLOG
    HOOKDEBUG = ui.configbool('anyhook', 'debug')
    HOOKLOG = ui.configbool('anyhook', 'log')


def wraphook(orig, ui, repo, name, throw=False, **args):
    ui.setconfig('hooks', name + '.anyhook', dispatch)
    return orig(ui, repo, name, throw=throw, **args)


def dispatch(ui, repo, hooktype, **kw):
    f = globals().get(hooktype.replace('-','_'))
    if f:
        if HOOKLOG:
            _log(repo, hooktype, kw)
        if HOOKDEBUG:
            msg = ' '.join('%s=%r'%x for x in kw.items())
            import sys, socket
            host = socket.gethostname()
            host = host and '(%s)' % host or ''
            print >>sys.stderr, 'HOOK', host, hooktype, msg
        return f(ui, repo, **kw)


def _log(repo, hook, kw):
    import os, getpass, json, datetime
    kw = dict((k, unicode(v)) for (k, v) in kw.items())
    env = dict((k, unicode(v)) for (k, v) in os.environ.items())
    msg = dict(user=getpass.getuser(),
               time=str(datetime.datetime.now()),
               hook=hook, args=kw, environ=env)
    msg = json.dumps(msg)
    fn = os.path.join(repo.path, 'hook.log')
    open(fn, 'a').write('%s\n' % msg)


def pretag(ui, repo, node, tag, local, **k):
    pass


def tag(ui, repo, node, tag, local, **k):
    pass


def precommit(ui, repo, parent1, parent2, **k):
    pass


def pretxncommit(ui, repo, node, parent1, parent2, pending, **k):
    pass


def commit(ui, repo, node, parent1, parent2, **k):
    pass


def preoutgoing(ui, repo, source, **k):
    'source in "serve", "push", "pull", "bundle"'
    pass


def outgoing(ui, repo, node, source, **k):
    'source in "serve", "push", "pull", "bundle"'
    pass


def prechangegroup(ui, repo, source, url, **k):
    pass


def pretxnchangegroup(ui, repo, node, source, url, pending, **k):
    pass


def changegroup(ui, repo, node, source, url, **k):
    pass


def incoming(ui, repo, node, source, url, **k):
    pass


def prepushkey(ui, repo, namespace, key, old, new, **k):
    pass


def pushkey(ui, repo, namespace, key, old, new, ret, **k):
    pass


def prelistkeys(ui, repo, namespace, **k):
    pass


def listkeys(ui, repo, namespace, values, **k):
    pass


def preupdate(ui, repo, parent1, parent2, **k):
    pass


def update(ui, repo, parent1, parent2, error, **k):
    pass


def _pre_status(ui, repo, args, pats, opts, **k):
    pass


def _post_status(ui, repo, args, pats, opts, result, **k):
    pass


