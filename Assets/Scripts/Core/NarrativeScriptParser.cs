using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

namespace Dreadmoor.Core
{
    /// <summary>
    /// Parser for the compact, author-facing narrative script format. It has no
    /// dependency on the retired scene-object schema: flow is determined by
    /// section order and native directives only.
    /// </summary>
    public static class NarrativeScriptParser
    {
        public static List<StoryNode> Parse(string source, string sourceName = "script")
        {
            if (source == null) throw Error(sourceName, 1, "Script source is null.");

            var lines = source.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n');
            var nodes = new List<StoryNode>();
            var currentId = "";
            var commands = new List<NarrativeCommand>();
            var explicitDestination = "";

            Action<int> finishNode = lineNumber =>
            {
                if (string.IsNullOrWhiteSpace(currentId)) return;
                if (commands.Count == 0)
                    throw Error(sourceName, lineNumber, $"Section '{currentId}' contains no directive.");
                var node = new StoryNode(currentId, commands.ToArray()) { ExplicitDestination = explicitDestination };
                nodes.Add(node);
                commands = new List<NarrativeCommand>();
                explicitDestination = "";
            };

            for (var index = 0; index < lines.Length; index++)
            {
                var line = lines[index];
                var trimmed = line.Trim();
                var lineNumber = index + 1;

                if (trimmed.Length == 0 || trimmed.StartsWith("#", StringComparison.Ordinal)) continue;
                if (trimmed.StartsWith("::", StringComparison.Ordinal))
                {
                    finishNode(lineNumber);
                    currentId = trimmed.Substring(2).Trim();
                    if (string.IsNullOrWhiteSpace(currentId)) throw Error(sourceName, lineNumber, "Section header requires an ID.");
                    continue;
                }

                if (string.IsNullOrWhiteSpace(currentId))
                    throw Error(sourceName, lineNumber, "Content must appear below a :: section header.");
                if (!trimmed.StartsWith("@", StringComparison.Ordinal))
                    throw Error(sourceName, lineNumber, "Expected a directive beginning with '@'.");

                var splitAt = IndexOfWhitespace(trimmed);
                var directive = (splitAt < 0 ? trimmed.Substring(1) : trimmed.Substring(1, splitAt - 1)).ToLowerInvariant();
                var argument = splitAt < 0 ? "" : trimmed.Substring(splitAt).Trim();

                switch (directive)
                {
                    case "typing":
                    {
                        var values = SplitLastToken(argument, sourceName, lineNumber, "@typing requires a sender and seconds.");
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.Typing, values.left, seconds: ParseSeconds(values.right, sourceName, lineNumber)));
                        break;
                    }
                    case "message":
                    {
                        Require(argument, sourceName, lineNumber, "@message requires a sender.");
                        var message = ReadFreeText(lines, ref index);
                        Require(message, sourceName, lineNumber, "@message requires text on the following line.");
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.Message, sender: argument, text: message));
                        break;
                    }
                    case "delay":
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.Delay, seconds: ParseSeconds(argument, sourceName, lineNumber)));
                        break;
                    case "choice":
                    {
                        var choices = ReadChoices(lines, ref index, sourceName, lineNumber);
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.Choice, choices: choices));
                        break;
                    }
                    case "switch_context":
                        Require(argument, sourceName, lineNumber, "@switch_context requires a context ID.");
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.ContextSwitch, contextId: argument));
                        break;
                    case "notification":
                        Require(argument, sourceName, lineNumber, "@notification requires text.");
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.Notification, text: argument));
                        break;
                    case "video":
                    {
                        var values = SplitFirstToken(argument, sourceName, lineNumber, "@video requires a sender and asset path.");
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.Video, sender: values.left, assetPath: values.right));
                        break;
                    }
                    case "news":
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.News, news: ReadNews(lines, ref index, sourceName, lineNumber)));
                        break;
                    case "diary":
                    {
                        var values = SplitFirstToken(argument, sourceName, lineNumber, "@diary requires a page ID and answer word.");
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.Diary, diary: new StoryDiaryGate(values.left, values.right)));
                        break;
                    }
                    case "intercept":
                        Require(argument, sourceName, lineNumber, "@intercept requires a context ID.");
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.Intercept, contextId: argument));
                        break;
                    case "glitch":
                    {
                        var values = SplitFirstToken(argument, sourceName, lineNumber, "@glitch requires seconds and display text.");
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.Glitch, text: values.right,
                            seconds: ParseSeconds(values.left, sourceName, lineNumber)));
                        break;
                    }
                    case "incoming_call":
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.IncomingCall,
                            call: ParseIncomingCall(argument, sourceName, lineNumber)));
                        break;
                    case "on_decline":
                    {
                        var incoming = commands.LastOrDefault(command => command.Kind == NarrativeCommandKind.IncomingCall);
                        if (incoming?.Call == null)
                            throw Error(sourceName, lineNumber, "@on_decline must follow @incoming_call in the same section.");
                        var values = SplitArrow(argument, sourceName, lineNumber, "@on_decline requires 'seconds -> SECTION_ID'.");
                        incoming.Call.DeclineDelaySeconds = ParseSeconds(values.left, sourceName, lineNumber);
                        incoming.Call.DeclineDestination = values.right;
                        break;
                    }
                    case "active_call":
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.ActiveCall,
                            call: ParseActiveCall(argument, sourceName, lineNumber)));
                        break;
                    case "credits":
                        Require(argument, sourceName, lineNumber, "@credits requires display text.");
                        commands.Add(new NarrativeCommand(NarrativeCommandKind.Credits, text: argument));
                        break;
                    case "goto":
                        Require(argument, sourceName, lineNumber, "@goto requires a section ID.");
                        if (!string.IsNullOrWhiteSpace(explicitDestination))
                            throw Error(sourceName, lineNumber, "A section may contain only one @goto.");
                        explicitDestination = argument;
                        break;
                    default:
                        throw Error(sourceName, lineNumber, $"Unknown directive '@{directive}'.");
                }
            }

            finishNode(lines.Length);
            if (nodes.Count == 0) throw Error(sourceName, 1, "Script contains no sections.");
            return nodes;
        }

        private static string ReadFreeText(string[] lines, ref int index)
        {
            var content = new List<string>();
            while (index + 1 < lines.Length)
            {
                var candidate = lines[index + 1];
                var trimmed = candidate.Trim();
                if (trimmed.StartsWith("::", StringComparison.Ordinal) || trimmed.StartsWith("@", StringComparison.Ordinal)) break;
                index++;
                content.Add(candidate);
            }
            while (content.Count > 0 && string.IsNullOrWhiteSpace(content[0])) content.RemoveAt(0);
            while (content.Count > 0 && string.IsNullOrWhiteSpace(content[content.Count - 1])) content.RemoveAt(content.Count - 1);
            return string.Join("\n", content).TrimEnd();
        }

        private static IReadOnlyList<StoryChoice> ReadChoices(string[] lines, ref int index, string sourceName, int directiveLine)
        {
            var choices = new List<StoryChoice>();
            while (index + 1 < lines.Length)
            {
                var candidate = lines[index + 1];
                var trimmed = candidate.Trim();
                if (trimmed.Length == 0)
                {
                    index++;
                    continue;
                }
                if (trimmed.StartsWith("::", StringComparison.Ordinal) || trimmed.StartsWith("@", StringComparison.Ordinal)) break;
                index++;
                var values = SplitArrow(trimmed, sourceName, index + 1, "Choice lines require 'text -> SECTION_ID'.");
                choices.Add(new StoryChoice(values.left, values.right));
            }
            if (choices.Count == 0) throw Error(sourceName, directiveLine, "@choice requires at least one option.");
            return choices;
        }

        private static StoryNews ReadNews(string[] lines, ref int index, string sourceName, int directiveLine)
        {
            var headline = "";
            var subheadline = "";
            var image = "";
            var caption = "";
            var body = new List<string>();
            var inBody = false;
            var paragraph = new List<string>();

            Action finishParagraph = () =>
            {
                if (paragraph.Count == 0) return;
                body.Add(string.Join("\n", paragraph).Trim());
                paragraph.Clear();
            };

            while (index + 1 < lines.Length)
            {
                var candidate = lines[index + 1];
                var trimmed = candidate.Trim();
                if (trimmed.StartsWith("::", StringComparison.Ordinal) || trimmed.StartsWith("@", StringComparison.Ordinal)) break;
                index++;

                if (!inBody)
                {
                    if (trimmed.StartsWith("headline:", StringComparison.OrdinalIgnoreCase))
                    {
                        headline = ValueAfterColon(trimmed);
                        continue;
                    }
                    if (trimmed.StartsWith("subheadline:", StringComparison.OrdinalIgnoreCase))
                    {
                        subheadline = ValueAfterColon(trimmed);
                        continue;
                    }
                    if (trimmed.StartsWith("image:", StringComparison.OrdinalIgnoreCase))
                    {
                        image = ValueAfterColon(trimmed);
                        continue;
                    }
                    if (trimmed.StartsWith("caption:", StringComparison.OrdinalIgnoreCase))
                    {
                        caption = ValueAfterColon(trimmed);
                        continue;
                    }
                    if (string.Equals(trimmed, "body:", StringComparison.OrdinalIgnoreCase))
                    {
                        inBody = true;
                        continue;
                    }
                    if (trimmed.Length == 0) continue;
                    throw Error(sourceName, index + 1, "@news accepts headline:, subheadline:, image:, caption:, and body: fields.");
                }

                if (trimmed.Length == 0) finishParagraph();
                else paragraph.Add(candidate);
            }
            finishParagraph();

            Require(headline, sourceName, directiveLine, "@news requires headline:.");
            Require(subheadline, sourceName, directiveLine, "@news requires subheadline:.");
            Require(image, sourceName, directiveLine, "@news requires image:.");
            if (!inBody) throw Error(sourceName, directiveLine, "@news requires body:.");
            return new StoryNews(headline, subheadline, image, caption, body.ToArray());
        }

        private static StoryCall ParseIncomingCall(string argument, string sourceName, int lineNumber)
        {
            var parts = SplitPipes(argument);
            if (parts.Length != 3 && parts.Length != 4)
                throw Error(sourceName, lineNumber, "@incoming_call requires 'name | number | ringtone' with optional '| forced'.");
            var forced = parts.Length == 4 && string.Equals(parts[3], "forced", StringComparison.OrdinalIgnoreCase);
            if (parts.Length == 4 && !forced)
                throw Error(sourceName, lineNumber, "The optional @incoming_call fourth value must be 'forced'.");
            Require(parts[0], sourceName, lineNumber, "@incoming_call requires a caller name.");
            Require(parts[1], sourceName, lineNumber, "@incoming_call requires a caller number.");
            return new StoryCall(parts[0], parts[1], parts[2], forced);
        }

        private static StoryCall ParseActiveCall(string argument, string sourceName, int lineNumber)
        {
            var parts = SplitPipes(argument);
            if (parts.Length != 3)
                throw Error(sourceName, lineNumber, "@active_call requires 'name | number | audio asset'.");
            Require(parts[0], sourceName, lineNumber, "@active_call requires a caller name.");
            Require(parts[1], sourceName, lineNumber, "@active_call requires a caller number.");
            Require(parts[2], sourceName, lineNumber, "@active_call requires an audio asset.");
            return new StoryCall(parts[0], parts[1], parts[2], false);
        }

        private static string[] SplitPipes(string input)
        {
            return input.Split('|').Select(part => part.Trim()).ToArray();
        }

        private static (string left, string right) SplitFirstToken(string input, string sourceName, int lineNumber, string message)
        {
            var position = IndexOfWhitespace(input);
            if (position < 0) throw Error(sourceName, lineNumber, message);
            var left = input.Substring(0, position).Trim();
            var right = input.Substring(position).Trim();
            if (left.Length == 0 || right.Length == 0) throw Error(sourceName, lineNumber, message);
            return (left, right);
        }

        private static (string left, string right) SplitLastToken(string input, string sourceName, int lineNumber, string message)
        {
            var position = input.LastIndexOf(' ');
            if (position < 0) throw Error(sourceName, lineNumber, message);
            var left = input.Substring(0, position).Trim();
            var right = input.Substring(position + 1).Trim();
            if (left.Length == 0 || right.Length == 0) throw Error(sourceName, lineNumber, message);
            return (left, right);
        }

        private static (string left, string right) SplitArrow(string input, string sourceName, int lineNumber, string message)
        {
            var position = input.LastIndexOf("->", StringComparison.Ordinal);
            if (position < 0) throw Error(sourceName, lineNumber, message);
            var left = input.Substring(0, position).Trim();
            var right = input.Substring(position + 2).Trim();
            if (left.Length == 0 || right.Length == 0) throw Error(sourceName, lineNumber, message);
            return (left, right);
        }

        private static float ParseSeconds(string value, string sourceName, int lineNumber)
        {
            if (!float.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out var seconds) || seconds < 0f)
                throw Error(sourceName, lineNumber, $"'{value}' is not a non-negative seconds value.");
            return seconds;
        }

        private static int IndexOfWhitespace(string input)
        {
            for (var index = 0; index < input.Length; index++)
                if (char.IsWhiteSpace(input[index])) return index;
            return -1;
        }

        private static string ValueAfterColon(string value)
        {
            var separator = value.IndexOf(':');
            return separator < 0 ? "" : value.Substring(separator + 1).Trim();
        }

        private static void Require(string value, string sourceName, int lineNumber, string message)
        {
            if (string.IsNullOrWhiteSpace(value)) throw Error(sourceName, lineNumber, message);
        }

        private static NarrativeScriptParseException Error(string sourceName, int lineNumber, string message)
        {
            return new NarrativeScriptParseException($"{sourceName}:{lineNumber}: {message}");
        }
    }

    public sealed class NarrativeScriptParseException : Exception
    {
        public NarrativeScriptParseException(string message) : base(message) { }
    }
}
