# Chat Feature — Refactored Architecture
## File Map

```
lib/features/chat/
│
├── chat_screen.dart                   ← Main StatefulWidget (state + business logic)
│   └── part: widgets/_attachment_sheet_widgets.dart
│
├── models/
│   └── chat_models.dart               ← All data types (no Flutter UI imports)
│
└── widgets/
    ├── messages_list.dart             ← ListView + empty state + scroll slot
    ├── message_bubble.dart            ← Single bubble (text/image/file/status)
    ├── typing_indicator.dart          ← 3-dot bounce + BotAvatar
    ├── ai_thinking_card.dart          ← Pulsing processing card
    ├── message_input_bar.dart         ← TextField + send button + attach button
    ├── attachment_preview.dart        ← Bottom-sheet file queue with thumbnails
    ├── _attachment_sheet_widgets.dart ← AttachmentPickerSheet, SourcePickerSheet (part)
    └── shared/
        └── chat_animations.dart       ← AnimatedMessageEntry, AnimatedThumbnail
```

---

## Widget Tree

```
ChatScreen (StatefulWidget)
│   owns: _messages, _typing, _pendingFiles, _textCtrl, _scroll
│
├── AppBar (built inline — lightweight, no extraction needed)
│
├── Expanded
│   └── MessagesList
│       ├── _EmptyState (overlay, visible while messages.length <= 1)
│       └── ListView.builder
│           ├── AnimatedMessageEntry (fade + slide, wraps every row)
│           │   ├── MessageBubble           ← text / image / file variants
│           │   │   ├── BotAvatar           ← shared avatar icon
│           │   │   ├── _BubbleContainer    ← colour, shape, shadow
│           │   │   ├── TypewriterText      ← animated bot text reveal
│           │   │   ├── _FileBubbleContent  ← PDF/doc icon + name
│           │   │   └── _MessageStatusIndicator  ← sending/sent/failed
│           │   ├── AIThinkingCard          ← when msg.isThinking
│           │   └── TypingIndicator         ← when isTyping && i == last slot
│
└── MessageInputBar
    ├── Attach button → _showAttachmentPicker()
    ├── TextField
    └── Send button (ScaleTransition + HapticFeedback)
```

---

## Data Flow

```
User types & taps Send
        │
        ▼
MessageInputBar.onSend()
        │
        ▼
ChatScreen._handleSend()
  ├── append ChatMessage to _messages   (optimistic UI)
  ├── set _typing = true
  ├── _scrollDown(force: true)
  ├── call ChatService / XRayService    (API)
  │       │
  │       ├─ file?  inject ChatMessage.thinking() card
  │       │         await API …
  │       │         remove thinking card
  │       │
  │       └─ text?  await API directly
  ├── append bot reply ChatMessage
  ├── set _typing = false
  └── _scrollDown()
```

```
User taps Attach
        │
        ▼
ChatScreen._showAttachmentPicker()
  └── _AttachmentPickerSheet  (bottom sheet)
          │  user picks category
          ▼
      _showSourcePicker()
  └── _SourcePickerSheet  (bottom sheet)
          │  user picks source
          ▼
      _pickMedia() / _pickFileForQueue()
          │  adds to _pendingFiles
          ▼
      _showPreviewSheet()
  └── AttachmentPreview  (bottom sheet)
          │  user taps "Send N files"
          ▼
      _sendPendingFiles()  → calls _handleSend() for each file
```

---

## Ownership Table

| Concern                        | Owner                        |
|-------------------------------|------------------------------|
| messages list state            | ChatScreen                   |
| typing flag                    | ChatScreen                   |
| pending files queue            | ChatScreen                   |
| API calls                      | ChatScreen                   |
| session ID                     | ChatScreen                   |
| scroll auto-advance            | ChatScreen (_scrollDown)     |
| scroll controller              | ChatScreen → passed to MessagesList |
| text controller                | ChatScreen → passed to MessageInputBar |
| send button scale animation    | MessageInputBar (local)      |
| haptic on send                 | MessageInputBar (local)      |
| bubble layout & colours        | MessageBubble                |
| typewriter effect              | TypewriterText (in bubble)   |
| expand / collapse long text    | MessageBubble (local state)  |
| copy on long-press             | MessageBubble (local)        |
| delivery status row            | _MessageStatusIndicator      |
| 3-dot bounce                   | TypingIndicator              |
| thinking card pulse            | AIThinkingCard               |
| entry animation (every row)    | AnimatedMessageEntry         |
| thumbnail entry animation      | AnimatedThumbnail            |
| file thumbnail strip           | AttachmentPreview            |
| attachment category picker     | _AttachmentPickerSheet       |
| source picker (cam/gallery/pdf)| _SourcePickerSheet           |
| empty state placeholder        | _EmptyState (in MessagesList)|

---

## Key Decisions

### Why `part` for `_attachment_sheet_widgets.dart`?
The attachment sheet widgets (_AttachmentPickerSheet, _SourcePickerSheet,
_AttachmentTile, _SourceButton, _SheetHandle) need access to AttachmentType
and AppColors but are too small to deserve their own library files.  Using
`part`/`part of` keeps them visually separate from `chat_screen.dart` without
requiring extra public exports or cross-file callbacks.

### Why does `MessageInputBar` own `_sendScale`?
The scale animation is 100% visual — it has no effect on message state.
Keeping the AnimationController inside MessageInputBar avoids polluting
ChatScreen with vsync boilerplate and makes the widget fully self-contained.

### Why is `BotAvatar` public (no underscore)?
Both `TypingIndicator` and `AIThinkingCard` render the same bot avatar.
Extracting it once and exporting it from `typing_indicator.dart` eliminates
the duplicate.

### Scroll guard (`_userScrolledUp`)
Owned by ChatScreen (the listener is on the ScrollController).  MessagesList
receives the controller as a prop and never reads `_userScrolledUp` directly —
ChatScreen decides when to scroll, MessagesList just renders.
