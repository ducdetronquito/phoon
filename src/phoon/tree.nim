import algorithm
import errors
import options
import strutils
import tables


type
    PathType* = enum
        Strict,
        Wildcard,
        Parametrized

    Node[T] = ref object
        path*: char
        children*: seq[Node[T]]
        value*: Option[T]

        case pathType*: PathType
        of PathType.Parametrized:
            parameterName*: string
        else:
            discard

        case isLeaf*: bool
        of true:
            parameters*: seq[string]
        of false:
            discard

    Tree*[T] = ref object
        root*: Node[T]

    Parameters* = ref object
        data: Table[string, string]

    Result*[T]= tuple
        value: T
        parameters: Parameters


proc fromKeys(table: type[Parameters], keys: seq[string], values: seq[string]): Parameters =
    result = Parameters()

    for index, key in keys:
        result.data[key] = values[index]

    return result

proc get*(self: Parameters, name: string): string =
    return self.data[name]


proc contains*(self: Parameters, name: string): bool =
    return self.data.hasKey(name)


proc new*[T](treeType: type[Tree[T]]): Tree[T] =
    var root = Node[T](path: '~')
    return Tree[T](root: root)


proc toDiagram*[T](self: Tree[T]): string =
    # Display a tree for debugging purposes
    #
    # Example:
    # For a tree defined with the 3 following routes:
    # - /a
    # - /bc
    # - /d
    #
    # It outputs a corresponding diagram where ★ describe leaf nodes:
    #   +- /
    #      +- a★
    #      +- b
    #         +- d★
    #      +- d★

    proc toDiagram[T](self: Node[T], indentation: string = "", isLastChildren: bool = true): string =
        result = ""

        var indentation = deepCopy(indentation)
        var row = indentation & "+- " & self.path
        if self.isLeaf:
            row.add("★")

        result.add(row & "\n")

        if isLastChildren:
            indentation.add("   ")
        else:
            indentation.add("|  ")

        for index, child in self.children:
            let childDiagram = child.toDiagram(indentation, index == self.children.len() - 1)
            result.add(childDiagram)

        return result

    return self.root.toDiagram()


proc findChildByPath[T](self: Node[T], path: char): Option[Node[T]] =
    for child in self.children:
        if child.path == path:
            return some(child)

    return none(Node[T])


proc removeChildByPath[T](self: Node[T], path: char) =
    for index, child in self.children:
        if child.path == path:
            self.children.del(index)
            return


proc checkIllegalPatterns(path: string) =
    if not path.contains("*"):
        return

    let afterWildcardPart = path.rsplit("*", maxsplit = 1)[1]
    if afterWildcardPart.len != 0:
        raise InvalidPathError(msg: "A path cannot defined character after a wildcard.")


proc byPathTypeOrder[T](x: Node[T], y: Node[T]): int =
    # Comparison function to order nodes by prioritizing path types as follow:
    # wildcard, parametrized and strict.
    if y.path == '*':
        return 1

    if x.path != '*' and y.path == '{':
        return 1

    return -1


proc addChildren[T](self: Tree[T], parent: Node[T], child: Node[T]) =
    parent.children.add(child)
    parent.children.sort(byPathTypeOrder[T])


proc insert*[T](self: Tree, path: string, value: T) =
    path.checkIllegalPatterns()

    var currentNode = self.root
    var parameterParsingEnabled: bool = false
    var parameterName: string
    var parameters: seq[string]

    for index, character in path:
        var character: char = character
        # ----- Collect paramater name ----
        if character == '{':
            if not parameterParsingEnabled:
                parameterParsingEnabled = true
                continue
            else:
                raise InvalidPathError(msg: "Cannot define a route with a parameter name containing the character '{'.")

        if character == '}':
            if parameterParsingEnabled:
                parameterParsingEnabled = false
                parameters.add(parameterName)
            else:
                raise InvalidPathError(msg: "A parameter name in a route must start with a '{' character.")

        if parameterParsingEnabled:
            parameterName.add(character)
            continue
        # ---------------------------------

        if parameterName.len() > 0:
            character = '{'

        let isLastCharacter = index == path.len() - 1
        let potentialChild = currentNode.findChildByPath(character)
        if potentialChild.isSome:
            var nextChild = potentialChild.unsafeGet()
            if nextChild.pathType == PathType.Strict and isLastCharacter:
                currentNode.removeChildByPath(character)
                self.addChildren(
                    currentNode,
                    Node[T](
                        path: character,
                        pathType: PathType.Strict,
                        isLeaf: true,
                        parameters: parameters,
                        children: nextChild.children,
                        value: some(value)
                    )
                )
                break

            if nextChild.pathType == PathType.Parametrized and nextChild.parameterName != parameterName:
                raise InvalidPathError(msg : "You cannot define the same route with two different parameter names.")
            else:
                currentNode = nextChild
                continue

        var child: Node[T]
        if parameterName.len() > 0:
            if isLastCharacter:
                child = Node[T](path: character, pathType: PathType.Parametrized, parameterName: parameterName, isLeaf: true, parameters: parameters)
            else:
                child = Node[T](path: character, pathType: PathType.Parametrized, parameterName: parameterName)
            parameterName = ""
        elif character == '*':
            if isLastCharacter:
                child = Node[T](path: character, pathType: PathType.Wildcard, isLeaf: true, parameters: parameters)
            else:
                child = Node[T](path: character, pathType: PathType.Wildcard)
        else:
            if isLastCharacter:
                child = Node[T](path: character, pathType: PathType.Strict, isLeaf: true, parameters: parameters)
            else:
                child = Node[T](path: character, pathType: PathType.Strict)

        self.addChildren(currentNode, child)
        currentNode = child

    currentNode.value = some(value)


type
    LookupContext[T] = ref object
        path: string
        currentPathIndex: int
        collectedParameters: seq[string]


proc pathIsFullyParsed[T](self: LookupContext[T]): bool =
    return self.path.len() == self.currentPathIndex


proc match[T](self: Node[T], context: LookupContext[T]): bool =
    case self.pathType:
    of PathType.Strict:
        if self.path == context.path[context.currentPathIndex]:
            context.currentPathIndex += 1
            return true
    of PathType.Wildcard:
        context.currentPathIndex = context.path.len()
        return true
    of PathType.Parametrized:
        var parameter = ""
        while context.currentPathIndex < context.path.len() and context.path[context.currentPathIndex] != '/':
            parameter.add(context.path[context.currentPathIndex])
            context.currentPathIndex += 1
        context.collectedParameters.add(parameter)
        return true

    return false


proc match*[T](self: Tree[T], path: string): Option[Result[T]] =
    var nodesToVisit = @[self.root.children[0]]
    var currentNode: Node[T]

    var context = LookupContext[T](path: path, currentPathIndex: 0)

    while nodesToVisit.len() > 0:
        currentNode = nodesToVisit.pop()
        let matched = currentNode.match(context)
        if not matched:
            continue

        if context.pathIsFullyParsed():
            if currentNode.isLeaf:
                let parameters= Parameters.fromKeys(currentNode.parameters, context.collectedParameters)
                let value = currentNode.value.unsafeGet()
                return some((value, parameters))
            else:
                return none(Result[T])
        else:
            for child in currentNode.children:
                nodesToVisit.add(child)
            continue

    return none(Result[T])
