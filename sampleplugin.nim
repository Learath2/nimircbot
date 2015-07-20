import plugiface, botiface

type SamplePlugin = ref object of PluginInterface
    botif: BotInterface

method onLoad(this: SamplePlugin, hnd: BotInterface) =
    this.botif = hnd

method onPrivMsg(this: SamplePlugin, origin, msg: string) = 
    this.botif.sendMsg(origin,"Got msg: "&msg)

proc newSamplePlugin*(): PluginInterface {.procvar.}=
    var res: SamplePlugin
    new(res)
    return PluginInterface(res)
