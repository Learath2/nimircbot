import plugiface, botiface, irc, asyncdispatch, strutils, future, tables
import sampleplugin

const
    nick = "NimIrcBot"
    ircServer = "irc.quakenet.org"
    versionText = "Unnamed Bot v0.0.0.0.0.0.1"

type 
    Bot = ref object of BotInterface
        ircHandle: PAsyncIrc
        channels: seq[string]
        allplugins: Table[string, (void -> PluginInterface)]
        loadedplugins: Table[string, PluginInterface]

    Error = enum
        success, errorNotfound, errorLoaded

method sendMsg(this: Bot, target, msg: string) = 
    asyncCheck this.ircHandle.privmsg(target, msg)

proc loadPlugin(bot: Bot, name: string): Error =
    if not bot.allplugins.hasKey(name):         #Plugin doesn't exist
        return errorNotfound
    elif bot.loadedplugins.hasKey(name):    #Plugin already loaded
        return errorLoaded

    var hnd: PluginInterface = bot.allplugins[name]()
    bot.loadedplugins[name] = hnd
    bot.loadedplugins[name].onLoad(bot)

    return success

proc unloadPlugin(bot: Bot, name: string): Error =
    if not bot.allplugins.hasKey(name):         #Plugin doesn't exist
        return errorNotfound
    elif not bot.loadedplugins.hasKey(name):    #PLugin not loaded
        return errorLoaded

    bot.loadedplugins[name].onUnload()
    bot.loadedplugins.del(name)

    return success

proc handleInternalCommands(hnd: PAsyncIrc, event: TIRCEvent, bot: Bot) {.async.} =
    let msg = event.params[1]

    if msg[0] != ',':
        return

    let
        tokens = msg.split(' ')
        cmd = tokens[0][1..len(tokens[0])]

    case cmd
    of "version":
        bot.sendMsg(event.origin, versionText)
    of "ping":
        bot.sendMsg(event.origin, "Pong!")
    of "loadplugin":
        if tokens.len > 0:
            case bot.loadPlugin(tokens[1])
            of success:
                bot.sendMsg(event.origin, tokens[1]&" Loaded")
            of errorNotfound:
                bot.sendMsg(event.origin, "Plugin "&tokens[1]&" not found")
            of errorLoaded:
                bot.sendMsg(event.origin, tokens[1]&" already loaded")
        else:
            bot.sendMsg(event.origin, "Command requires arguments")
    of "unloadplugin":
        if tokens.len > 0:
            case bot.unloadPlugin(tokens[1])
            of errorNotfound:
                bot.sendMsg(event.origin, "Plugin "&tokens[1]&" not found")
            of  errorLoaded:
                bot.sendMsg(event.origin, tokens[1]&" isn't loaded")
            of  success:
                bot.sendMsg(event.origin, tokens[1]&" Unloaded")
        else:
            bot.sendMsg(event.origin, "Command requires arguments")
    else:
        discard

proc handleIrcMsg(hnd: PAsyncIrc, event: TIRCEvent, bot: Bot) {.async.} =
    #Call every plugins hooks
    case event.cmd
    of MPrivMsg:
        for i in bot.loadedplugins.values:
            i.onPrivMsg(event.origin, event.params[1])
        await handleInternalCommands(hnd, event, bot)
    of MJoin:
        for i in bot.loadedplugins.values:
            i.onUserJoin(event.origin, event.nick)
    of MPart:
        for i in bot.loadedplugins.values:
            i.onUserLeave(event.origin, event.nick)
    of MQuit:
        for i in bot.loadedplugins.values:
            i.onUserQuit(event.origin, event.nick)
    of MTopic:
        for i in bot.loadedplugins.values:
            i.onTopicChange(event.origin, event.params[1])
    else:
        discard

proc handleIrcEvent(hnd: PAsyncIrc, event: TIRCEvent, bot: Bot) {.async.} =
    case event.typ
    of EvConnected:
        discard
    of EvDisconnected:
        await hnd.reconnect()
    of EvMsg:
        await handleIrcMsg(hnd, event, bot)
    else:
        discard

proc populatePlugins(bot: Bot) =
    bot.allplugins["sampleplugin"]= newSamplePlugin

proc init(): Bot =
    var res: Bot
    new(res)

    res.ircHandle = newAsyncIrc(address = ircServer, nick = nick,
        user = nick, realname = nick, joinChans = @["#Lea2"],
        callback = (hnd: PAsyncIrc, ev: TIRCEvent) => (handleIrcEvent(hnd, ev, res)))

    #Initialize plugin tables
    res.allplugins = initTable[string, (void -> PluginInterface)]()
    res.loadedplugins = initTable[string, PluginInterface]()

    #Load all internal plugins
    populatePlugins(res)

    return res

var bot = init()
asyncCheck bot.ircHandle.run()

runForever()
