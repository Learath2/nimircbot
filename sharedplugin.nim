import botififace
from math import random

type SharedPlugin* = ref object of PluginInterface
    botif: BotInterface
    instid: int

method onLoad(this: SharedPlugin, hnd: BotInterface) =
    this.botif = hnd
    this.instid = random(100)

proc getInstanceID*(this: SharedPlugin): int =
    return this.instid

proc newSharedPlugin*(): PluginInterface {.procvar.}=
    var res: SharedPlugin
    new(res)
    return PluginInterface(res)
