import algorithm
import express/routing/errors
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
        parameters*: TableRef[string, string]


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


proc by_path_type_order[T](x: Node[T], y: Node[T]): int =
    # Comparison function to order nodes by prioritizing path types as follow:
    # strict, parametrized and wildcard.
    if y.path == '*':
        return -1

    if x.path != '*' and y.path == '{':
        return -1

    return 1


proc add_children[T](self: var Tree[T], parent: var Node[T], child: Node[T]) =
    parent.children.add(child)
    parent.children.sort(by_path_type_order[T])


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

        let matching_node = current_node.find_child_by_path(character)
        if matching_node.isSome:
            current_node = matching_node.get()
            if current_node.path_type == PathType.Parametrized and current_node.parameter_name != parameter_name:
                raise InvalidPathError(msg : "You cannot define the same route with two different parameter names.")
            else:
                continue

        var child: Node[T]
        if parameter_name.len() > 0:
            child = Node[T](path: character, path_type: PathType.Parametrized, parameter_name: parameter_name)
            parameter_name = ""
        elif character == '*':
            child = Node[T](path: character, path_type: PathType.Wildcard)
        else:
            child = Node[T](path: character, path_type: PathType.Strict)

        self.add_children(current_node, child)
        current_node = child

    current_node.value = some(value)
    current_node.is_leaf = true


proc retrieve*[T](self: var Tree[T], path: string): Option[Result[T]] =
    var current_node = self.root
    var parameters = new TableRef[string, string]
    var wildcard_match: Option[Node[T]]

    var i = -1
    while i < path.len() - 1:
        i = i + 1
        var match_found = false

        for child in current_node.children:
            case child.path_type
            of PathType.Strict:
                if child.path == path[i]:
                    current_node = child
                    match_found = true
            of PathType.Wildcard:
                wildcard_match = some(child)
                match_found = true
            of PathType.Parametrized:
                var parameter = ""
                while i < path.len() and path[i] != '/':
                    parameter.add(path[i])
                    i = i + 1
                parameters.add(child.parameter_name, parameter)

                # Make sure the / is re-evaluated
                if i < path.len() and path[i] == '/':
                    i = i - 1

                current_node = child
                match_found = true

        if not match_found:
            if wildcard_match.isSome:
                return some(Result[T](value: wildcard_match.get().value.get(), parameters: parameters))
            else:
                return none(Result[T])

    if current_node.is_leaf:
        return some(Result[T](value: current_node.value.get(), parameters: parameters))
    elif wildcard_match.isSome:
        return some(Result[T](value: wildcard_match.get().value.get(), parameters: parameters))
    else:
        return none(Result[T])
