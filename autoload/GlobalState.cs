using Godot;
using System;
using System.Collections.Generic;

namespace Dreadmoor.Autoload
{
    public partial class GlobalState : Node
    {
        [Signal] public delegate void SaveDataLoadedEventHandler();
        [Signal] public delegate void StateChangedEventHandler(string key);

        private Dictionary<string, Variant> _state = new Dictionary<string, Variant>();
        private const string SavePath = "user://save_data.json";

        public override void _Ready()
        {
            LoadState();
        }

        public Variant GetValue(string key, Variant defaultValue = default)
        {
            if (_state.TryGetValue(key, out Variant value))
            {
                return value;
            }
            return defaultValue;
        }

        public void SetValue(string key, Variant value)
        {
            _state[key] = value;
            EmitSignal(SignalName.StateChanged, key);
            SaveState();
        }

        public void SaveState()
        {
            var file = FileAccess.Open(SavePath, FileAccess.ModeFlags.Write);
            if (file != null)
            {
                var godotDict = new Godot.Collections.Dictionary();
                foreach (var kvp in _state)
                {
                    godotDict[kvp.Key] = kvp.Value;
                }

                string jsonString = Json.Stringify(godotDict);
                file.StoreString(jsonString);
                file.Close();
            }
            else
            {
                GD.PrintErr("Failed to open save file for writing.");
            }
        }

        public void LoadState()
        {
            if (!FileAccess.FileExists(SavePath)) return;

            var file = FileAccess.Open(SavePath, FileAccess.ModeFlags.Read);
            if (file != null)
            {
                string jsonString = file.GetAsText();
                file.Close();

                var json = new Json();
                var error = json.Parse(jsonString);

                if (error == Error.Ok && json.Data.VariantType == Variant.Type.Dictionary)
                {
                    var dict = json.Data.AsGodotDictionary();
                    _state = new Dictionary<string, Variant>();
                    foreach (var key in dict.Keys)
                    {
                        _state[key.AsString()] = dict[key];
                    }
                    EmitSignal(SignalName.SaveDataLoaded);
                }
                else
                {
                    GD.PrintErr($"JSON Parse Error: {json.GetErrorMessage()}");
                }
            }
        }
    }
}
