import context


type
    Callback* = proc(context: Context)
    Middleware* = proc (callback: Callback): Callback


proc apply*(self: Callback, middlewares: seq[Middleware]): Callback =
    if middlewares.len() == 0:
        return self

    result = self
    for middleware in middlewares:
        result = middleware(result)

    return result
