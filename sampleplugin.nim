import plugiface, botiface

type SamplePlugin* = ref object of PluginInterface
    botif: BotInterface

method onLoad(this: SamplePlugin, hnd: BotInterface) =
    this.botif = hnd

method onChanMsg(this: SamplePlugin, origin, msg: string) = 
    this.botif.sendMsg(origin,"Got msg: "&msg)
