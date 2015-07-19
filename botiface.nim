type BotInterface = ref object of RootObj
    discard

method sendMsg(this: BotInterface, target, msg: string) =
    discard