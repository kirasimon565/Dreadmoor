# SCENE_5_START
Type: Chat_Event
Chat: Secret_Intercept_Amelia_Michael
Theme: Secret_Hacked
Sender: amelia
Action: Notification
Text: [VPN: ACTIVE | ENCRYPTION: 256-BIT | IDENTITY: HIDDEN]
Next: [[S5_Amelia_Panic]]

---

# S5_Amelia_Panic
Type: Chat_Event
Sender: amelia
Action: Typing
Text: Did you tell them? Anything at all?
Next: [[S5_Michael_Cold]]

# S5_Michael_Cold
Type: Chat_Event
Sender: michael
Text: No. I’m not that stupid, Amelia.
Next: [[S5_Amelia_Relief]]

# S5_Amelia_Relief
Type: Chat_Event
Sender: amelia
Action: Typing
Text: Good. Thank god.
Next: [[S5_Amelia_Relief_2]]

# S5_Amelia_Relief_2
Type: Chat_Event
Sender: amelia
Action: Pause
Duration: 3000
Text: Because if that gets out… if they find out what we were actually doing at that factory…
Next: [[S5_Michael_ShutDown]]

# S5_Michael_ShutDown
Type: Chat_Event
Sender: michael
Action: Typing
Text: It won't get out. Not unless you keep spiraling like this.
Next: [[S5_Michael_ShutDown_2]]

# S5_Michael_ShutDown_2
Type: Chat_Event
Sender: michael
Text: Relax. Breathe. The police are looking for a missing person, not a motive.
Next: [[S5_Amelia_Doubt]]

# S5_Amelia_Doubt
Type: Chat_Event
Sender: amelia
Action: Typing
Text: But that 'stranger' in the group… they knew about the timeline. They knew she didn't leave at midnight.
Next: [[S5_Michael_Dismissive]]

# S5_Michael_Dismissive
Type: Chat_Event
Sender: michael
Action: Typing
Text: A lucky guess. Or someone’s idea of a sick joke. 
Next: [[S5_Michael_Dismissive_2]]

# S5_Michael_Dismissive_2
Type: Chat_Event
Sender: michael
Text: I'm handling the press. You just keep Chris and Abigail quiet.
Next: [[S5_Amelia_Guilt]]

# S5_Amelia_Guilt
Type: Chat_Event
Sender: amelia
Action: Pause
Duration: 2000
Text: She looked so scared, Michael. When she went outside... I just wanted to teach her a lesson. I didn't want this.
Next: [[S5_Michael_Final_Warning]]

# S5_Michael_Final_Warning
Type: Chat_Event
Sender: michael
Action: Typing
Text: Stop. Don't type another word about that.
Next: [[S5_Michael_Final_Warning_2]]

# S5_Michael_Final_Warning_2
Type: Chat_Event
Sender: michael
Text: We stick to the story. She left at midnight. We didn't see anything.
Next: [[S5_Michael_Final_Warning_3]]

# S5_Michael_Final_Warning_3
Type: Chat_Event
Sender: michael
Action: Typing
Text: If we change a single detail now, we’re both finished.
Next: [[S5_CONNECTION_GLITCH]]

---

# S5_CONNECTION_GLITCH
Type: System_Event
Action: Glitch_Effect
Duration: 1000
Text: [SIGNAL LOST... ENCRYPTION BREACHED...]
Next: [[SCENE_6_START]]
