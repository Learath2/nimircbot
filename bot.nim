import plugiface, botiface, irc, asyncdispatch
import sampleplugin

const
    ircServer = "irc.quakenet.org"
    versionText = "Unnamed Bot v0.0.0.0.0.0.1"

type Bot = ref object of BotInterface
    ircHandle: PAsycnIrc
    channels: seq[string]
    plugins: seq[PluginInterface]

method sendMsg(this: Bot, target, msg: string) = 
    this.ircHandle.privmsg(target, msg)

proc handleInternalCommands(hnd: PAsycnIrc, event: TIRCEvent, bot: Bot) {.async.} =
    let msg = ev.params[1]

    if msg[0] != ',':
        return

    let
        tokens = msg.split(' ')
        cmd = tokens[0][1..len(tokens[0])]
        args = tokens[1..len(tokens)]

    case cmd
    of "version":
        sendMsg(bot, event.origin, versionText)
    of "ping":
        sendMsg(bot, event.origin, "pong")

proc handleIrcMsg(hnd: PAsycnIrc, event: TIRCEvent, bot: Bot) {.async.} =
    case event.cmd
    of MPrivMsg:
        await handleInternalCommands(hnd, event, bot)
        for i in bot.plugins:
            i.onPrivMsg(event.origin, event.params[1])
    of MJoin:
        for i in bot.plugins:
            i.onUserJoin(event.origin, event.params[1])
    of MPart:
        for i in bot.plugins:
            i.onUserLeave(event.origin, event.params[1])
    of MQuit:
        for i in bot.plugins:
            i.onUserQuit(event.origin, event.params[1])
    of MTopic:
        for i in bot.plugins:
            i.onTopicChange(event.origin, event.params[1])
    else:
        discard

proc handleIrcEvent(hnd: PAsyncIrc, event: TIRCEvent, bot: Bot) {.async.} =
    case event.type
    of EvConnected:
        discard
    of EvDisconnected:
        await hnd.reconnect()
    of EvMsg:
        await handleIrcMsg(hnd, event)
    else:
        discard

proc loadPlugins(bot: Bot) =
    bot.plugins.add(new(SamplePlugin))

    for i in bot.plugins:
        i.onLoad(bot)

proc init(): Bot =
    new(result)

    result.ircHandle = newAsyncIrc(address: ircServer, nick: "IrcBotTest",
        user: "IrcBotTest", realname: "IrcBotTest", joinChans: @["#Lea2"],
        callback: (hnd: PAsyncIrc, ev: TIRCEvent) => (handleIrcEvent(hnd, ev, result)))

    loadPlugins(result)

    return result

var bot = init()
asyncCheck bot.ircHandle.run()

runForever()