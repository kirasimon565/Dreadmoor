# SCENE_4_START
Type: Chat_Event
Chat: Private_Unknown
Sender: Unknown
Text: Keep your eyes on this.
Next: [[S4_VIDEO_NODE]]

---

# S4_VIDEO_NODE
Type: Video_Message
Chat: Private_Unknown
Sender: Unknown
File_Asset: assets/media/videos/party_clip.mp4
Duration: 10
Next: [[S4_Player_Reaction]]

---

# S4_Player_Reaction
Type: Player_Choice
- Option: "Where the hell did you get this?" -> [[S4_Unknown_Source]]

# S4_Unknown_Source
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: Same place I found their chat logs. 
Next: [[S4_Unknown_Explain]]

# S4_Unknown_Explain
Type: Chat_Event
Sender: Unknown
Text: Someone recorded the party and tried to wipe the evidence. They missed a backup.
Next: [[S4_Player_Realization]]

# S4_Player_Realization
Type: Player_Choice
- Option: "Rebecca is in the background. She's still there." -> [[S4_Unknown_Confirm]]

# S4_Unknown_Confirm
Type: Chat_Event
Sender: Unknown
Action: Pause
Duration: 1500
Text: Exactly. Which proves the 'midnight' story is a lie.
Next: [[S4_The_Mission]]

# S4_The_Mission
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: Go back to the group. Watch them. One of them is cracking.
Next: [[S4_SWITCH_GROUP]]

---

# S4_SWITCH_GROUP
Type: System_Event
Action: Switch_Context
Target: Group_Dreadmoor_News
Next: [[S4_Group_Loop]]

---

# S4_Group_Loop
Type: Chat_Event
Sender: chris
Action: Typing
Text: I don't get it. Why is everyone obsessing over the time?
Next: [[S4_Abigail_Echo]]

# S4_Abigail_Echo
Type: Chat_Event
Sender: abigail
Text: Seriously. She left. That’s the only part that matters.
Next: [[S4_Michael_Pressure]]

# S4_Michael_Pressure
Type: Chat_Event
Sender: michael
Action: Typing
Text: It matters because consistency is the only thing that keeps the police away.
Next: [[S4_Michael_Pressure_2]]

# S4_Michael_Pressure_2
Type: Chat_Event
Sender: michael
Text: If three people give three different stories, it's not a 'mistake' anymore. It's a red flag.
Next: [[S4_Abigail_Defend]]

# S4_Abigail_Defend
Type: Chat_Event
Sender: abigail
Text: We aren't. We're all saying the same thing.
Next: [[S4_Michael_Counter]]

# S4_Michael_Counter
Type: Chat_Event
Sender: michael
Action: Pause
Duration: 1000
Text: Midnight. Outside for air. Didn't see her leave.
Next: [[S4_Michael_Counter_2]]

# S4_Michael_Counter_2
Type: Chat_Event
Sender: michael
Text: Those aren't 'the same thing,' Abigail.
Next: [[S4_Amelia_Hostile]]

# S4_Amelia_Hostile
Type: Chat_Event
Sender: amelia
Action: Typing
Text: Stop twisting our words, Michael. You're acting like something happened.
Next: [[S4_Michael_Neutral]]

# S4_Michael_Neutral
Type: Chat_Event
Sender: michael
Text: I'm just repeating what was said. If it sounds suspicious, maybe it is.
Next: [[S4_Choice_Entry]]

---

# S4_Choice_Entry
Type: Player_Choice
- Option: "The timeline doesn't fit. You're hiding something." -> [[S4_Group_React_B]]
- Option: "Rebecca is missing and you're arguing about semantics?" -> [[S4_Group_React_A]]

# S4_Group_React_A
Type: Chat_Event
Sender: amelia
Text: Semantics? We’ve been up all night with investigators!
Next: [[S4_Michael_Question]]

# S4_Group_React_B
Type: Chat_Event
Sender: chris
Text: Hiding something? You don't even know us!
Next: [[S4_Michael_Question]]

# S4_Michael_Question
Type: Chat_Event
Sender: michael
Action: Typing
Text: Let's cut to the chase. 
Next: [[S4_Michael_Question_2]]

# S4_Michael_Question_2
Type: Chat_Event
Sender: michael
Text: When was the absolute LAST time anyone saw Rebecca inside that factory?
Next: [[S4_The_Slip]]

---

# S4_The_Slip
Type: Chat_Event
Sender: chris
Action: Typing
Text: Around 1—
Next: [[S4_Amelia_Interruption]]

# S4_Amelia_Interruption
Type: Chat_Event
Sender: amelia
Action: Stop_Typing
Text: Chris. Stop.
Next: [[S4_Michael_Catch]]

# S4_Michael_Catch
Type: Chat_Event
Sender: michael
Action: Pause
Duration: 2000
Text: 'Around one' what, Chris?
Next: [[S4_Chris_Backtrack]]

# S4_Chris_Backtrack
Type: Chat_Event
Sender: chris
Text: I'm just guessing! We were all drinking. No one had a stopwatch.
Next: [[S4_Abigail_Exit]]

# S4_Abigail_Exit
Type: Chat_Event
Sender: abigail
Text: This is getting weird. I'm done with this.
Next: [[S4_Group_Offline]]

# S4_Group_Offline
Type: System_Notification
Text: Abigail and Chris went offline.
Next: [[S4_Amelia_Last]]

# S4_Amelia_Last
Type: Chat_Event
Sender: amelia
Text: I'm not doing this. Leave it to the police.
Next: [[S4_Amelia_Offline]]

# S4_Amelia_Offline
Type: System_Notification
Text: Amelia went offline.
Next: [[S4_Michael_Closing]]

# S4_Michael_Closing
Type: Chat_Event
Sender: michael
Action: Typing
Text: Something about last night feels... unfinished.
Next: [[SCENE_5_START]]
