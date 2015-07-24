import botiface, sharedplugin, strutils

type SamplePlugin = ref object of PluginInterface
    botif: BotInterface
    sphnd: SharedPlugin

method onLoad(this: SamplePlugin, hnd: BotInterface) =
    this.botif = hnd

method onPrivMsg(this: SamplePlugin, origin, msg: string) = 
    if msg[0] != ',':
        return

    let
        tokens = msg.split(' ')
        cmd = tokens[0][1..len(tokens[0])]

    case cmd
    of "ping":
        this.sphnd = SharedPlugin(this.botif.getPluginHandle("sharedplugin"))
        var id: string
        if this.sphnd != nil:
            id = $(this.sphnd.getInstanceID())
        else:
            id = "--"
        this.botif.sendMsg(origin, "["&id&"] Pong!")
    else:
        discard

proc newSamplePlugin*(): PluginInterface {.procvar.}=
    var res: SamplePlugin
    new(res)
    return PluginInterface(res)
