import options


type
    Node[T] = ref object
        label*: char
        children*: seq[Node[T]]
        value*: Option[T]
        is_leaf: bool

    Tree*[T] = ref object
        root*: Node[T]


proc new*[T](tree_type: type[Tree[T]]): Tree[T] =
    var root = system.new(Node[T])
    root.label = '~'
    return tree_type(root: root)


proc find_child_by_label[T](self: Node[T], label: char): Option[Node[T]] =
    for child in self.children:
        if child.label == label:
            return some(child)

    return none(Node[T])


proc insert*[T](self: var Tree, path: string, value: T) =
    var current_node = self.root

    for character in path:

        let child = current_node.find_child_by_label(character)
        if child.isSome:
            current_node = child.get()
            continue

        var node = new Node[T]
        node.label = character

        current_node.children.add(node)
        current_node = node

    current_node.value = some(value)
    current_node.is_leaf = true


proc retrieve*[T](self: var Tree[T], path: string): Option[T] =
    var current_node = self.root

    for character in path:
        let child = current_node.find_child_by_label(character)
        if child.isNone:
            return none(T)

        current_node = child.get()

    if current_node.is_leaf:
        return some(current_node.value.get())
    else:
        return none(T)