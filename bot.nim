import plugiface, botiface, irc, asyncdispatch, strutils, future
import sampleplugin

const
    ircServer = "irc.quakenet.org"
    versionText = "Unnamed Bot v0.0.0.0.0.0.1"

type Bot = ref object of BotInterface
    ircHandle: PAsyncIrc
    channels: seq[string]
    plugins: seq[PluginInterface]

method sendMsg(this: Bot, target, msg: string) = 
    asyncCheck this.ircHandle.privmsg(target, msg)

proc handleInternalCommands(hnd: PAsyncIrc, event: TIRCEvent, bot: Bot) {.async.} =
    let msg = event.params[1]

    if msg[0] != ',':
        return

    let
        tokens = msg.split(' ')
        cmd = tokens[0][1..len(tokens[0])]

    case cmd
    of "version":
        sendMsg(bot, event.origin, versionText)
    of "ping":
        sendMsg(bot, event.origin, "Pong!")
    else:
        discard

proc handleIrcMsg(hnd: PAsyncIrc, event: TIRCEvent, bot: Bot) {.async.} =
    case event.cmd
    of MPrivMsg:
        await handleInternalCommands(hnd, event, bot)
        for i in bot.plugins:
            i.onPrivMsg(event.origin, event.params[1])
    of MJoin:
        for i in bot.plugins:
            i.onUserJoin(event.origin, event.nick)
    of MPart:
        for i in bot.plugins:
            i.onUserLeave(event.origin, event.nick)
    of MQuit:
        for i in bot.plugins:
            i.onUserQuit(event.origin, event.nick)
    of MTopic:
        for i in bot.plugins:
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

proc loadPlugins(bot: Bot) =
    bot.plugins = @[]
    var obj = SamplePlugin()
    bot.plugins.add(PluginInterface(obj))

    for i in bot.plugins:
        i.onLoad(bot)

proc init(): Bot =
    var res: Bot
    new(res)

    res.ircHandle = newAsyncIrc(address = ircServer, nick = "IrcBotTest",
        user = "IrcBotTest", realname = "IrcBotTest", joinChans = @["#Lea2"],
        callback = (hnd: PAsyncIrc, ev: TIRCEvent) => (handleIrcEvent(hnd, ev, res)))

    loadPlugins(res)

    return res

var bot = init()
asyncCheck bot.ircHandle.run()

runForever()
