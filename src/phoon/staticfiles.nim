import asyncdispatch, httpcore, mimetypes, strutils, uri
from os import fileExists, joinPath, searchExtPos
import context, request, response


let mimeDb = newMimeTypes()


proc serve*(ctx: Context) {.async.} =
    let decodedPath = decodeUrl(ctx.request.path())
    let filePath = joinPath(ctx.config.publicDirectory, "../", decodedPath)

    if not filePath.startsWith(ctx.config.publicDirectory):
        ctx.response.status(Http404)
        return

    if not fileExists(filePath):
        ctx.response.status(Http404)
        return

    let extPos = searchExtPos(filePath)
    if extPos != -1:
        let extension = filePath[extPos + 1 .. filePath.high]
        let mimeType = mimeDb.getMimetype(extension)
        if mimeType != "":
            ctx.response.headers("Content-Type", mimeType)

    let content = readFile(filePath)
    ctx.response.status(Http200).body(content)
