# SCENE_3_START
Type: Chat_Event
Chat: Group_Dreadmoor_News
Sender: System
Text: [PlayerName] was added to the group.
Next: [[S3_Initial_Shock]]

---

# S3_Initial_Shock
Type: Chat_Event
Sender: amelia
Action: Pause
Duration: 2000
Text: Wait, who just added [PlayerName]?
Next: [[S3_Chris_Denial]]

# S3_Chris_Denial
Type: Chat_Event
Sender: chris
Text: Not me.
Next: [[S3_Abigail_Skeptic]]

# S3_Abigail_Skeptic
Type: Chat_Event
Sender: abigail
Text: Is this some kind of prank? This isn't the time.
Next: [[S3_Michael_Mediator]]

# S3_Michael_Mediator
Type: Chat_Event
Sender: michael
Action: Typing
Text: Everyone take a breath. Let's just ask before we start guessing.
Next: [[S3_Amelia_Direct]]

# S3_Amelia_Direct
Type: Chat_Event
Sender: amelia
Action: Typing
Text: Fine.
Next: [[S3_Amelia_Direct_2]]

# S3_Amelia_Direct_2
Type: Chat_Event
Sender: amelia
Text: Who are you? And how did you get an invite to this thread?
Next: [[S3_Choice_Intro]]

---

# S3_Choice_Intro
Type: Player_Choice
- Option: "I think I was added by mistake." -> [[S3_Branch_Mistake]]
- Option: "I'm here because of Rebecca." -> [[S3_Branch_Rebecca]]
- Option: "Depends on who's asking." -> [[S3_Branch_Aggressive]]

# S3_Branch_Mistake
Type: Chat_Event
Sender: chris
Text: Mistake? Nobody here added you, so that's impossible.
Next: [[S3_Abigail_Push]]

# S3_Branch_Rebecca
Type: Chat_Event
Sender: amelia
Action: Typing
Text: What about her? The news is already out.
Next: [[S3_Abigail_Push]]

# S3_Branch_Aggressive
Type: Chat_Event
Sender: amelia
Text: Excuse me? You're the one intruding here.
Next: [[S3_Abigail_Push]]

# S3_Abigail_Push
Type: Chat_Event
Sender: abigail
Text: Amelia, just kick them. We don't need this right now.
Next: [[S3_Chris_Agree]]

# S3_Chris_Agree
Type: Chat_Event
Sender: chris
Action: Typing
Text: Yeah, I'm on it—
Next: [[S3_Michael_Intervene]]

# S3_Michael_Intervene
Type: Chat_Event
Sender: michael
Action: Stop_Typing
Text: Wait.
Next: [[S3_Michael_Intervene_2]]

# S3_Michael_Intervene_2
Type: Chat_Event
Sender: michael
Action: Typing
Text: You clearly joined for a reason, [PlayerName]. What is it?
Next: [[S3_Choice_WhyHere]]

---

# S3_Choice_WhyHere
Type: Player_Choice
- Option: "I'm trying to find her." -> [[S3_Search_Reaction]]
- Option: "The news report... something doesn't feel right." -> [[S3_Sus_Reaction]]

# S3_Search_Reaction
Type: Chat_Event
Sender: amelia
Text: You? Looking for my sister?
Next: [[S3_Michael_ID_Check]]

# S3_Sus_Reaction
Type: Chat_Event
Sender: chris
Text: 'Doesn't feel right'? What's that supposed to mean?
Next: [[S3_Michael_ID_Check]]

# S3_Michael_ID_Check
Type: Chat_Event
Sender: michael
Action: Typing
Text: Look, you still haven't explained who you are.
Next: [[S3_Choice_Identity]]

---

# S3_Choice_Identity
Type: Player_Choice
- Option: "I knew her. We were... close." -> [[S3_KnewHer_Branch]]
- Option: "My identity doesn't matter. Rebecca is missing." -> [[S3_NoID_Branch]]

# S3_KnewHer_Branch
Type: Chat_Event
Sender: abigail
Text: Close? That's funny. She never mentioned a "[PlayerName]."
Next: [[S3_Michael_Logic]]

# S3_NoID_Branch
Type: Chat_Event
Sender: chris
Text: It matters when you're lurking in a private chat.
Next: [[S3_Michael_Logic]]

# S3_Michael_Logic
Type: Chat_Event
Sender: michael
Action: Typing
Text: Actually, it matters a lot. You didn't get in here by accident.
Next: [[S3_Michael_Logic_2]]

# S3_Michael_Logic_2
Type: Chat_Event
Sender: michael
Text: Tell us something useful. Why are you *really* involved?
Next: [[S3_Choice_Motivation]]

---

# S3_Choice_Motivation
Type: Player_Choice
- Option: "Because no one else seems to be taking this seriously." -> [[S3_Motivation_A]]
- Option: "Because your story to the police is full of holes." -> [[S3_Motivation_B]]

# S3_Motivation_A
Type: Chat_Event
Sender: amelia
Action: Typing
Text: Excuse m—
Next: [[S3_Amelia_Typo]]

# S3_Amelia_Typo
Type: Chat_Event
Sender: amelia
Text: *me. You think we haven't been dealing with this all night?
Next: [[S3_Michael_Warning]]

# S3_Motivation_B
Type: Chat_Event
Sender: michael
Text: Holes? That’s a bold claim for someone who wasn't there.
Next: [[S3_Michael_Warning]]

# S3_Michael_Warning
Type: Chat_Event
Sender: michael
Action: Typing
Text: Either way, you clearly have a theory.
Next: [[S3_Michael_Warning_2]]

# S3_Michael_Warning_2
Type: Chat_Event
Sender: michael
Text: So say it. What do you think happened to Rebecca?
Next: [[S3_Choice_The_Theory]]

---

# S3_Choice_The_Theory
Type: Player_Choice
- Option: "I think someone in this group is lying." -> [[S3_Liar_Branch]]
- Option: "I think she didn't leave when you claim she did." -> [[S3_Timeline_Branch]]

# S3_Liar_Branch
Type: Chat_Event
Sender: chris
Text: Are you serious right now? You don't even know us.
Next: [[S3_Michael_Timeline_Interject]]

# S3_Timeline_Branch
Type: Chat_Event
Sender: abigail
Text: We told the police exactly what we saw. She left.
Next: [[S3_Michael_Timeline_Interject]]

# S3_Michael_Timeline_Interject
Type: Chat_Event
Sender: michael
Action: Typing
Text: Interesting.
Next: [[S3_Michael_Timeline_Interject_2]]

# S3_Michael_Timeline_Interject_2
Type: Chat_Event
Sender: michael
Text: So it's the timeline. Specifically, the moment she left.
Next: [[S3_Chris_Defensive]]

# S3_Chris_Defensive
Type: Chat_Event
Sender: chris
Text: Midnight. She left around midnight.
Next: [[S3_Abigail_Backup]]

# S3_Abigail_Backup
Type: Chat_Event
Sender: abigail
Text: That's what we all said.
Next: [[S3_Michael_Doubt]]

# S3_Michael_Doubt
Type: Chat_Event
Sender: michael
Action: Typing
Text: 'Around midnight.'
Next: [[S3_Michael_Doubt_2]]

# S3_Michael_Doubt_2
Type: Chat_Event
Sender: michael
Action: Pause
Duration: 1500
Text: That usually means no one actually checked their phone.
Next: [[S3_Amelia_Final]]

# S3_Amelia_Final
Type: Chat_Event
Sender: amelia
Text: She left. End of story. I'm not debating this with a stranger.
Next: [[S3_TRIGGER_UNKNOWN]]

---

# S3_TRIGGER_UNKNOWN
Type: System_Event
Action: Switch_Context
Target: Private_Chat_Unknown
Next: [[SCENE_4_START]]
