sed -i 's/\x27assets\/media\/images\/forest_moon_bg.png\x27/snap.data?.backgroundPath ?? \x27assets\/media\/images\/default_chat_bg.png\x27/g' lib/features/messenger/ui/screens/chat/chat_screen.dart
sed -i 's/\x27forest_moon_bg\x27/snap.data?.backgroundPath ?? \x27default_chat_bg\x27/g' lib/features/messenger/ui/screens/chat/chat_screen.dart
