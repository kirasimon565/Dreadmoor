extends Node

# Since it needs to act as a globally available class to mimic static methods,
# it will be an Autoload.

func ParseScene(filePath: String) -> Dictionary:
    var graph: Dictionary = {}

    if not FileAccess.file_exists(filePath):
        push_error("JSON file not found: " + filePath)
        return graph

    var file = FileAccess.open(filePath, FileAccess.READ)
    if not file:
        push_error("Failed to open JSON file: " + filePath)
        return graph

    var jsonText = file.get_as_text()
    var json = JSON.new()
    var error = json.parse(jsonText)

    if error != OK:
        push_error("JSON Parse Error: %s at line %d" % [json.get_error_message(), json.get_error_line()])
        return graph

    var data = json.get_data()

    if typeof(data) == TYPE_ARRAY:
        for element in data:
            if typeof(element) == TYPE_DICTIONARY:
                if element.has("id") and typeof(element["id"]) == TYPE_STRING:
                    graph[element["id"]] = element
    else:
        push_error("Failed to parse JSON scene %s: Root is not an array." % filePath)

    return graph
