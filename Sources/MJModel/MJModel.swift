@attached(member, names: overloaded)
public macro MJModel() = #externalMacro(module: "MJModelMacros", type: "MJModel")

@attached(peer)
public macro MJModelKey(_ key: String ...) = #externalMacro(module: "MJModelMacros", type: "MJModelKey")

@attached(peer)
public macro MJModelIgnore() = #externalMacro(module: "MJModelMacros", type: "MJModelIgnore")
