using Godot;
using System;

namespace Dreadmoor
{
    public partial class GameClock : Node
    {
        public static GameClock Instance { get; private set; }

        // Base starting point: Sunday, June 12, 2016 00:00:00 (Unix: 1465689600)
        // Storing as Unix timestamp seconds for easy math, but conceptually based on Flutter implementation
        public long CurrentGameTimeUnix { get; private set; } = 1465689600;

        [Signal]
        public delegate void GameTimeAdvancedEventHandler(long newTimeUnix);

        public override void _EnterTree()
        {
            if (Instance == null)
            {
                Instance = this;
            }
        }

        public void AdvanceMinutes(int minutes)
        {
            CurrentGameTimeUnix += (minutes * 60);
            EmitSignal(SignalName.GameTimeAdvanced, CurrentGameTimeUnix);
        }

        public void AdvanceSeconds(int seconds)
        {
            CurrentGameTimeUnix += seconds;
            EmitSignal(SignalName.GameTimeAdvanced, CurrentGameTimeUnix);
        }

        public DateTime GetCurrentDateTime()
        {
            return DateTimeOffset.FromUnixTimeSeconds(CurrentGameTimeUnix).UtcDateTime;
        }

        public string GetFormattedTime()
        {
            return GetCurrentDateTime().ToString("HH:mm");
        }

        public string GetFormattedDate()
        {
            return GetCurrentDateTime().ToString("MMM d, yyyy");
        }
    }
}
