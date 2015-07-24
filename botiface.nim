type 
    PluginInterface* = ref object of RootObj
        discard

    BotInterface* = ref object of RootObj
        discard

method getPluginHandle*(this:BotInterface, name: string): PluginInterface =
    discard

method sendMsg*(this: BotInterface, target, msg: string) =
    discard

method onLoad*(this: PluginInterface, hnd: BotInterface) =
    discard

method onUnload*(this: PluginInterface) =
    discard

method onPrivMsg*(this: PluginInterface, orig, msg: string) = 
    discard

method onBotMsg*(this: PluginInterface, target, msg: string): string =
    discard

method onUserJoin*(this: PluginInterface, orig, user: string) =
    discard

method onUserLeave*(this: PluginInterface, orig, user: string) =
    discard

method onUserQuit*(this: PluginInterface, orig, user: string) =
    discard

method onTopicChange*(this: PluginInterface, orig, topic: string) =
    discard
