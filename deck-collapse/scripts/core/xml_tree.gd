## Reads an XML document into a simple tree of nodes, and escapes text for writing XML.
## A node is a Dictionary: { "name": String, "attrs": Dictionary, "text": String, "children": Array }.
class_name XmlTree
extends RefCounted


## Parses XML text and returns the root element node, or an empty Dictionary if the text has no element.
static func parse(xml_text: String) -> Dictionary:
	var parser := XMLParser.new()
	if parser.open_buffer(xml_text.to_utf8_buffer()) != OK:
		return {}
	var root := {}
	var open_nodes: Array = []
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var node := {"name": parser.get_node_name(), "attrs": {}, "text": "", "children": []}
				for i in parser.get_attribute_count():
					node.attrs[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
				if open_nodes.is_empty():
					root = node
				else:
					open_nodes.back().children.append(node)
				if not parser.is_empty():
					open_nodes.append(node)
			XMLParser.NODE_ELEMENT_END:
				if not open_nodes.is_empty():
					open_nodes.pop_back()
			XMLParser.NODE_TEXT, XMLParser.NODE_CDATA:
				if not open_nodes.is_empty():
					open_nodes.back().text += parser.get_node_data()
	return root


## Reads a whole file and parses it. Returns an empty Dictionary if the file can't be read.
static func parse_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	return parse(FileAccess.get_file_as_string(path))


## The child nodes with the given element name.
static func children_named(node: Dictionary, element_name: String) -> Array:
	return node.get("children", []).filter(func(child): return child.name == element_name)


## The node's own text with whitespace collapsed to single spaces.
static func clean_text(node: Dictionary) -> String:
	var text := String(node.get("text", "")).replace("\r", " ").replace("\n", " ").replace("\t", " ")
	return " ".join(text.split(" ", false))


## Escapes text so it can go inside an XML attribute or element.
static func escape(text: String) -> String:
	return text.xml_escape(true)
