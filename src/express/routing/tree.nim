import options
import strutils
import express/routing/errors


type
    PathType* = enum
        Strict,
        Wildcard,
        Parametrized

    Node[T] = ref object
        path*: char
        children*: seq[Node[T]]
        value*: Option[T]
        is_leaf: bool

        case path_type*: PathType
        of PathType.Parametrized:
            parameter_name*: string
        else:
            discard

    Tree*[T] = ref object
        root*: Node[T]

    Result*[T] = object
        value*: T


proc new*[T](tree_type: type[Tree[T]]): Tree[T] =
    var root = Node[T](path: '~')
    return tree_type(root: root)


proc find_child_by_path[T](self: Node[T], path: char): Option[Node[T]] =
    for child in self.children:
        if child.path == path:
            return some(child)

    return none(Node[T])


proc check_illegal_patterns(path: string) =
    if not path.contains("*"):
        return

    let after_wildcard_part = path.rsplit("*", maxsplit = 1)[1]
    if after_wildcard_part.len != 0:
        raise InvalidPathError(msg: "A path cannot defined character after a wildcard.")


proc insert*[T](self: var Tree, path: string, value: T) =
    path.check_illegal_patterns()

    var current_node = self.root

    var parameter_parsing_enabled: bool = false
    var parameter_name: string

    for character in path:
        var character: char = character
        var path_type: PathType = PathType.Strict
        # ----- Collect paramater name ----
        if character == '{':
            if not parameter_parsing_enabled:
                parameter_parsing_enabled = true
                continue
            else:
                raise InvalidPathError(msg: "Cannot define a route with a parameter name containing the character '{'.")

        if character == '}':
            if parameter_parsing_enabled:
                parameter_parsing_enabled = false
            else:
                raise InvalidPathError(msg: "A parameter name in a route must start with a '{' character.")

        if parameter_parsing_enabled:
            parameter_name.add(character)
            continue
        # ---------------------------------

        if parameter_name.len() > 0:
            character = '{'

        let child = current_node.find_child_by_path(character)
        if child.isSome:
            current_node = child.get()
            if current_node.path_type == PathType.Parametrized and current_node.parameter_name != parameter_name:
                raise InvalidPathError(msg : "You cannot define the same route with two different parameter names.")
            else:
                continue

        var node: Node[T]
        if parameter_name.len() > 0:
            node = Node[T](path: character, path_type: PathType.Parametrized, parameter_name: parameter_name)
            parameter_name = ""
        elif character == '*':
            node = Node[T](path: character, path_type: PathType.Wildcard)
        else:
            node = Node[T](path: character, path_type: PathType.Strict)

        current_node.children.add(node)
        current_node = node

    current_node.value = some(value)
    current_node.is_leaf = true


proc retrieve*[T](self: var Tree[T], path: string): Option[Result[T]] =
    var current_node = self.root

    var wildcard_match: Option[Node[T]]

    for character in path:
        var match_found = false

        for child in current_node.children:
            case child.path_type
            of PathType.Strict:
                if child.path == character:
                    current_node = child
                    match_found = true
            of PathType.Wildcard:
                wildcard_match = some(child)
                match_found = true
            of PathType.Parametrized:
                continue

        if not match_found:
            if wildcard_match.isSome:
                return some(Result[T](value: wildcard_match.get().value.get()))
            else:
                return none(Result[T])

    if current_node.is_leaf:
        return some(Result[T](value: current_node.value.get()))
    elif wildcard_match.isSome:
        return some(Result[T](value: wildcard_match.get().value.get()))
    else:
        return none(Result[T])
