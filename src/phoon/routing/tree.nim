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

        case path_type*: PathType
        of PathType.Parametrized:
            parameter_name*: string
        else:
            discard

        case is_leaf*: bool
        of true:
            parameters*: seq[string]
        of false:
            discard

    Tree*[T] = ref object
        root*: Node[T]

    Parameters* = ref object
        data: Table[string, string]

    Result*[T] = object
            value*: T
            parameters*: Parameters


proc from_keys(table: type[Parameters], keys: seq[string], values: seq[string]): Parameters =
    result = Parameters()

    for index, key in keys:
        result.data[key] = values[index]

    return result

proc get*(self: Parameters, name: string): string =
    return self.data[name]


proc contains*(self: Parameters, name: string): bool =
    return self.data.hasKey(name)


proc new*[T](tree_type: type[Tree[T]]): Tree[T] =
    var root = Node[T](path: '~')
    return tree_type(root: root)


proc to_diagram*[T](self: Tree[T]): string =
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

    proc to_diagram[T](self: Node[T], indentation: string = "", is_last_children: bool = true): string =
        result = ""

        var indentation = deepCopy(indentation)
        var row = indentation & "+- " & self.path
        if self.is_leaf:
            row.add("★")

        result.add(row & "\n")

        if is_last_children:
            indentation.add("   ")
        else:
            indentation.add("|  ")

        for index, child in self.children:
            let child_diagram = child.to_diagram(indentation, index == self.children.len() - 1)
            result.add(child_diagram)

        return result

    return self.root.to_diagram()


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
    # wildcard, parametrized and strict.
    if y.path == '*':
        return 1

    if x.path != '*' and y.path == '{':
        return 1

    return -1


proc add_children[T](self: var Tree[T], parent: var Node[T], child: Node[T]) =
    parent.children.add(child)
    parent.children.sort(by_path_type_order[T])


proc insert*[T](self: var Tree, path: string, value: T) =
    path.check_illegal_patterns()

    var current_node = self.root
    var parameter_parsing_enabled: bool = false
    var parameter_name: string
    var parameters: seq[string]

    for index, character in path:
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
                parameters.add(parameter_name)
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
        let is_last_character = index == path.len() - 1
        if parameter_name.len() > 0:
            if is_last_character:
                child = Node[T](path: character, path_type: PathType.Parametrized, parameter_name: parameter_name, is_leaf: true, parameters: parameters)
            else:
                child = Node[T](path: character, path_type: PathType.Parametrized, parameter_name: parameter_name)
            parameter_name = ""
        elif character == '*':
            if is_last_character:
                child = Node[T](path: character, path_type: PathType.Wildcard, is_leaf: true, parameters: parameters)
            else:
                child = Node[T](path: character, path_type: PathType.Wildcard)
        else:
            if is_last_character:
                child = Node[T](path: character, path_type: PathType.Strict, is_leaf: true, parameters: parameters)
            else:
                child = Node[T](path: character, path_type: PathType.Strict)

        self.add_children(current_node, child)
        current_node = child

    current_node.value = some(value)


type
    LookupContext[T] = ref object
        path: string
        current_path_index: int
        potential_matches: seq[Node[T]]
        collected_parameters: seq[string]


proc path_is_fully_parsed[T](self: LookupContext[T]): bool =
    return self.path.len() == self.current_path_index


proc match[T](self: Node[T], context: var LookupContext[T]): bool =
    case self.path_type:
    of PathType.Strict:
        if self.path == context.path[context.current_path_index]:
            context.current_path_index += 1
            return true
    of PathType.Wildcard:
        context.current_path_index = context.path.len()
        return true
    of PathType.Parametrized:
        var parameter = ""
        while context.current_path_index < context.path.len() and context.path[context.current_path_index] != '/':
            parameter.add(context.path[context.current_path_index])
            context.current_path_index += 1
        context.collected_parameters.add(parameter)
        return true

    return false


proc match*[T](self: Tree[T], path: string): Option[Result[T]] =
    var nodes_to_visit = @[self.root.children[0]]
    var current_node: Node[T]

    var context = LookupContext[T](path: path, current_path_index: 0)

    while nodes_to_visit.len() > 0:
        current_node = nodes_to_visit.pop()
        let matched = current_node.match(context)
        if not matched:
            continue

        if context.path_is_fully_parsed():
            if current_node.is_leaf:
                return some(
                    Result[T](
                        value: current_node.value.get(),
                        parameters: Parameters.from_keys(current_node.parameters, context.collected_parameters)
                    )
                )
            else:
                return none(Result[T])
        else:
            for child in current_node.children:
                nodes_to_visit.add(child)
            continue

    return none(Result[T])