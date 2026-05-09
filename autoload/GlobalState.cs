using Godot;
using System;
using System.Collections.Generic;

namespace Dreadmoor
{
    public partial class GlobalState : Node
    {
        public static GlobalState Instance { get; private set; }

        public string ActiveEpisodeId { get; set; } = "ep01";
        public string CurrentNodeId { get; set; } = "SCENE_1_NEWS_ARTICLE";
        public string ActiveChoiceId { get; set; } = null;

        public Dictionary<string, bool> Flags { get; private set; } = new Dictionary<string, bool>();
        public Dictionary<string, string> Variables { get; private set; } = new Dictionary<string, string>();

        [Signal]
        public delegate void FlagChangedEventHandler(string flagName, bool value);

        public override void _EnterTree()
        {
            if (Instance == null)
            {
                Instance = this;

                // Initialize default variables needed for UI prototype
                SetVariable("Ep01Progress", "15");
                SetVariable("PlayerName", "Detective");
                SetVariable("ActiveThread", "Rebecca Stone");
            }
        }

        public void SetFlag(string flagName, bool value)
        {
            Flags[flagName] = value;
            EmitSignal(SignalName.FlagChanged, flagName, value);
        }

        public bool GetFlag(string flagName, bool defaultValue = false)
        {
            if (Flags.TryGetValue(flagName, out bool val))
                return val;
            return defaultValue;
        }

        public void SetVariable(string varName, string value)
        {
            Variables[varName] = value;
        }

        public string GetVariable(string varName, string defaultValue = "")
        {
            if (Variables.TryGetValue(varName, out string val))
                return val;
            return defaultValue;
        }

        public void Save()
        {
            // Real implementation will use Godot's FileAccess and JSON/ConfigFile to user://
            GD.Print("GlobalState: Saving data...");
        }

        public void Load()
        {
            // Real implementation will load from user://
            GD.Print("GlobalState: Loading data...");
        }
    }
}
