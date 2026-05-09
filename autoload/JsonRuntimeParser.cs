using Godot;
using System;
using System.Collections.Generic;
using System.Text.Json;

namespace Dreadmoor
{
    // Helper to parse JSON files into a flat graph dictionary
    public static class JsonRuntimeParser
    {
        public static Dictionary<string, Dictionary<string, object>> ParseScene(string filePath)
        {
            var graph = new Dictionary<string, Dictionary<string, object>>();

            if (!FileAccess.FileExists(filePath))
            {
                GD.PrintErr($"JSON file not found: {filePath}");
                return graph;
            }

            using var file = FileAccess.Open(filePath, FileAccess.ModeFlags.Read);
            string jsonText = file.GetAsText();

            try
            {
                // Basic parse: array of nodes
                var doc = JsonDocument.Parse(jsonText);
                if (doc.RootElement.ValueKind == JsonValueKind.Array)
                {
                    foreach (var element in doc.RootElement.EnumerateArray())
                    {
                        var nodeDict = ElementToDictionary(element);
                        if (nodeDict.TryGetValue("id", out var idObj) && idObj is string id)
                        {
                            graph[id] = nodeDict;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                GD.PrintErr($"Failed to parse JSON scene {filePath}: {ex.Message}");
            }

            return graph;
        }

        private static Dictionary<string, object> ElementToDictionary(JsonElement element)
        {
            var dict = new Dictionary<string, object>();

            if (element.ValueKind == JsonValueKind.Object)
            {
                foreach (var prop in element.EnumerateObject())
                {
                    dict[prop.Name] = GetElementValue(prop.Value);
                }
            }

            return dict;
        }

        private static object GetElementValue(JsonElement element)
        {
            switch (element.ValueKind)
            {
                case JsonValueKind.String: return element.GetString();
                case JsonValueKind.Number: return element.GetDouble(); // simplify all numbers
                case JsonValueKind.True: return true;
                case JsonValueKind.False: return false;
                case JsonValueKind.Object: return ElementToDictionary(element);
                case JsonValueKind.Array:
                    var list = new List<object>();
                    foreach (var item in element.EnumerateArray())
                    {
                        list.Add(GetElementValue(item));
                    }
                    return list;
                default: return null;
            }
        }
    }
}
