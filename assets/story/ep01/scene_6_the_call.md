# SCENE_6_START
Type: Phone_Call_Event
Caller_ID: Unknown_Number
Status: Ringing
Audio_Loop: assets/media/sfx/phone_ringtone_glitch.mp3
Next_On_Decline: [[S6_Decline_1]]
Next_On_Accept: [[S6_Accept_Call]]

---

# S6_Decline_1
Type: System_Event
Action: Update_Call_Log
Text: Call Declined.
Next: [[S6_Wait_1]]

# S6_Wait_1
Type: System_Event
Action: UI_Pause
Duration: 2000
Text: (2 seconds pass...)
Next: [[S6_Ringing_2]]

---

# S6_Ringing_2
Type: Phone_Call_Event
Caller_ID: Unknown_Number
Status: Ringing
Next_On_Decline: [[S6_Decline_2]]
Next_On_Accept: [[S6_Accept_Call]]

# S6_Decline_2
Type: System_Event
Action: Update_Call_Log
Text: Call Declined.
Next: [[S6_Wait_2]]

# S6_Wait_2
Type: System_Event
Action: UI_Pause
Duration: 3000
Text: (3 seconds pass...)
Next: [[S6_Ringing_Final]]

---

# S6_Ringing_Final
Type: Phone_Call_Event
Caller_ID: Unknown_Number
Status: Force_Ringing
Action: Disable_Decline_Button
Note: The 'Decline' button glitches out or vibrates when pressed, forcing an 'Accept'.
Next_On_Accept: [[S6_Accept_Call]]

---

# S6_Accept_Call
Type: Full_Screen_Call_UI
Status: Connected
Audio_Asset: assets/media/sfx/threatening_call_01.mp3
Visual_Effect: Audio_Waveform_Glitch
Next: [[EPISODE_1_END]]

---

# EPISODE_1_END
Type: System_Event
Action: Trigger_Credits
Text: TO BE CONTINUED IN EPISODE 2
