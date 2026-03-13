# SCENE_2_START
Type: Chat_Event
Chat: Private_Unknown
Sender: Unknown
Action: Notification
Text: Well… that’s convenient.
Next: [[S2_Player_Intro]]

---

# S2_Player_Intro
Type: Player_Choice
- Option: "Who the hell are you? How did you get my number?" -> [[S2_Unknown_Rebuttal]]

---

# S2_Unknown_Rebuttal
Type: Chat_Event
Chat: Private_Unknown
Sender: Unknown
Action: Typing
Text: Relax. My identity is the least of your concerns right now.
Next: [[S2_Unknown_Hook]]

# S2_Unknown_Hook
Type: Chat_Event
Chat: Private_Unknown
Sender: Unknown
Text: You should be asking about Rebecca Stone.
Next: [[S2_Choice_HowKnow]]

---

# S2_Choice_HowKnow
Type: Player_Choice
- Option: "How do you know her?" -> [[S2_Branch_A]]
- Option: "If this is some kind of sick joke, cut it out." -> [[S2_Branch_B]]
- Option: "I'm listening. Talk." -> [[S2_Branch_C]]

# S2_Branch_A
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: Because she actually trusted me. Unlike the people she was with.
Next: [[S2_The_Factory_Lead]]

# S2_Branch_B
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: Look at the news, [PlayerName]. Does any of this look like a joke to you?
Next: [[S2_The_Factory_Lead]]

# S2_Branch_C
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: Straight to the point. I like that. Pay attention.
Next: [[S2_The_Factory_Lead]]

---

# S2_The_Factory_Lead
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: Rebecca didn't just vanish into thin air. She went to that factory for a reason.
Next: [[S2_Player_PartyQuery]]

# S2_Player_PartyQuery
Type: Player_Choice
- Option: "The article said it was just a party." -> [[S2_The_Sister_Reveal]]

# S2_The_Sister_Reveal
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: A party? Sure. But the press missed the best part: who organized it.
Next: [[S2_Player_WhatMean]]

# S2_Player_WhatMean
Type: Player_Choice
- Option: "What are you implying?" -> [[S2_Amelia_Accusation]]

# S2_Amelia_Accusation
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: Her sister. Amelia. She hand-picked that derelict hellhole.
Next: [[S2_Choice_AmeliaLogic]]

---

# S2_Choice_AmeliaLogic
Type: Player_Choice
- Option: "That doesn't make sense. Why would she?" -> [[S2_Amelia_Reasoning]]
- Option: "How are you so sure Amelia called the shots?" -> [[S2_Amelia_Reasoning]]

# S2_Amelia_Reasoning
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: Because she handled the invites. She chose the isolation. No neighbors, no witnesses.
Next: [[S2_Amelia_Scare]]

# S2_Amelia_Scare
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: It was supposed to be a 'scare.' A dramatic stunt for attention.
Next: [[S2_Player_ScareGoal]]

# S2_Player_ScareGoal
Type: Player_Choice
- Option: "You think she staged the whole disappearance?" -> [[S2_The_Phone_Call]]

# S2_The_Phone_Call
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: That’s what Rebecca told me herself. 
Next: [[S2_Choice_WhenTalk]]

---

# S2_Choice_WhenTalk
Type: Player_Choice
- Option: "She talked to you right before she vanished?" -> [[S2_Timeline_Details]]
- Option: "When exactly was this?" -> [[S2_Timeline_Details]]

# S2_Timeline_Details
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: 11:30 PM. She stepped outside to find a signal and called me.
Next: [[S2_Something_Off]]

# S2_Something_Off
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: She was playing it cool, but her voice was shaking. She was in a hurry.
Next: [[S2_The_Hangup]]

# S2_The_Hangup
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: She didn't even answer my question before hanging up. That was the last time I heard her.
Next: [[S2_Player_Question]]

# S2_Player_Question
Type: Player_Choice
- Option: "What did you ask her?" -> [[S2_The_Last_Words]]

# S2_The_Last_Words
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: I asked if she was okay. She lied and said yes.
Next: [[S2_The_Last_Words_2]]

# S2_The_Last_Words_2
Type: Chat_Event
Sender: Unknown
Action: Pause
Duration: 2000
Text: I asked if Amelia had done something. She ignored me and said she'd call back.
Next: [[S2_The_Last_Words_3]]

# S2_The_Last_Words_3
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: She never did.
Next: [[S2_Choice_WhatSaying]]

---

# S2_Choice_WhatSaying
Type: Player_Choice
- Option: "So what are you getting at?" -> [[S2_The_Mismatch]]
- Option: "What happened after she hung up?" -> [[S2_The_Mismatch]]

# S2_The_Mismatch
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: I'm saying the 'official' timeline is garbage. 
Next: [[S2_The_Coordination]]

# S2_The_Coordination
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: The group is already aligning their stories. Coordinating what to feed the police.
Next: [[S2_Player_HowKnow]]

# S2_Player_HowKnow
Type: Player_Choice
- Option: "How can you possibly know that?" -> [[S2_The_Intercept]]

# S2_The_Intercept
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: Because I'm watching their private group chat right now.
Next: [[S2_The_Intercept_2]]

# S2_The_Intercept_2
Type: Chat_Event
Sender: Unknown
Action: Pause
Duration: 1500
Text: They're nervous. Their stories don't match, and they know it.
Next: [[S2_Choice_WhatSayingGroup]]

---

# S2_Choice_WhatSayingGroup
Type: Player_Choice
- Option: "What is Amelia saying?" -> [[S2_Group_Intel_A]]
- Option: "What about the others?" -> [[S2_Group_Intel_B]]
- Option: "Show me exactly what they're saying." -> [[S2_Group_Intel_C]]

# S2_Group_Intel_A
Type: Chat_Event
Sender: Unknown
Text: Amelia claims Rebecca left at midnight. Says she didn't see which way she went.
Next: [[S2_The_Invitation]]

# S2_Group_Intel_B
Type: Chat_Event
Sender: Unknown
Text: It's a mess. Chris didn't see her leave. Abigail thought she went for air. Michael is staying silent.
Next: [[S2_The_Invitation]]

# S2_Group_Intel_C
Type: Chat_Event
Sender: Unknown
Text: Amelia: Midnight. Chris: Didn't see her. Abigail: Guessed she went outside. Michael: Non-committal.
Next: [[S2_The_Invitation]]

---

# S2_The_Invitation
Type: Chat_Event
Sender: Unknown
Action: Typing
Text: They’re careful, but I've found a way in. I'm adding you to the group.
Next: [[S2_The_Warning]]

# S2_The_Warning
Type: Chat_Event
Sender: Unknown
Action: Pause
Duration: 1000
Text: Don't reveal what you know. Just observe. Wait for them to slip up.
Next: [[S2_Choice_FinalReady]]

---

# S2_Choice_FinalReady
Type: Player_Choice
- Option: "Do it. Get me in." -> [[S2_Add_Success]]
- Option: "Wait, I'm not sure about this." -> [[S2_Add_Forced]]

# S2_Add_Success
Type: Chat_Event
Sender: Unknown
Text: Good. Don't say anything stupid.
Next: [[S2_SYSTEM_ADD]]

# S2_Add_Forced
Type: Chat_Event
Sender: Unknown
Text: Hesitating won't save her. Every second you wait, they perfect the lie.
Next: [[S2_SYSTEM_ADD]]

# S2_SYSTEM_ADD
Type: System_Notification
Text: You were added to DREADMOOR’S NEWS
Next: [[SCENE_3_START]]
