# Local Notification Contract

**Feature**: Forest-Style Pomodoro Timer
**Service**: NotificationService
**Date**: 2026-01-14

This contract defines the structure, identifiers, and behavior of local notifications used for session completion alerts.

## Overview

The app uses `UNUserNotificationCenter` to schedule and deliver local notifications when a focus session completes while the app is backgrounded. Notifications are scheduled when a session starts and cancelled if the session is abandoned or the user completes it in the foreground.

---

## Notification Types

### 1. Session Completion Notification

**Identifier Format**: `session-complete-{UUID}`

**Trigger**: 25-minute countdown from session start (UNTimeIntervalNotificationTrigger)

**Content**:

```swift
{
    "title": "Your tree is complete!",
    "body": "Great work! Your tree has been saved to your forest.",
    "sound": "default",
    "badge": null,
    "categoryIdentifier": "SESSION_COMPLETE",
    "userInfo": {
        "sessionID": "{UUID}",
        "completedAt": "{ISO8601Timestamp}",
        "notificationType": "sessionComplete"
    }
}
```

**Example**:
```swift
let content = UNMutableNotificationContent()
content.title = "Your tree is complete!"
content.body = "Great work! Your tree has been saved to your forest."
content.sound = .default
content.categoryIdentifier = "SESSION_COMPLETE"
content.userInfo = [
    "sessionID": sessionID.uuidString,
    "completedAt": ISO8601DateFormatter().string(from: Date()),
    "notificationType": "sessionComplete"
]

let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: 25 * 60,  // 25 minutes in seconds
    repeats: false
)

let request = UNNotificationRequest(
    identifier: "session-complete-\(sessionID.uuidString)",
    content: content,
    trigger: trigger
)

UNUserNotificationCenter.current().add(request) { error in
    if let error = error {
        print("Error scheduling notification: \(error)")
    }
}
```

---

## Notification Actions

**Category**: `SESSION_COMPLETE`

**Actions**: None (informational only, no action buttons)

**User Interaction**:
- Tapping notification: Opens app to forest view showing newly completed tree
- Dismissing notification: No action (tree is already saved)

**Category Registration** (in AppDelegate or @main):

```swift
let category = UNNotificationCategory(
    identifier: "SESSION_COMPLETE",
    actions: [],
    intentIdentifiers: [],
    options: []
)

UNUserNotificationCenter.current().setNotificationCategories([category])
```

---

## Permission Handling

### Request Permission

**Timing**: On first app launch or before first session start

**Authorization Options**: `.alert`, `.sound`, `.badge`

```swift
UNUserNotificationCenter.current().requestAuthorization(
    options: [.alert, .sound, .badge]
) { granted, error in
    if granted {
        print("Notification permission granted")
    } else {
        print("Notification permission denied")
    }
}
```

### Permission Denied Behavior

**Spec Requirement**: "What happens when a user denies notification permissions? (Session still works, but completion notification won't fire—show in-app message instead)"

**Implementation**:
- Session completion logic proceeds normally (saves tree, updates stats)
- If notification permission is denied, show in-app alert when user returns to foreground:
  ```swift
  "Your tree is complete! You've earned your tree."
  ```
- Do NOT block session start or completion due to denied permissions

### Check Permission Status

```swift
UNUserNotificationCenter.current().getNotificationSettings { settings in
    switch settings.authorizationStatus {
    case .authorized:
        // Can schedule notifications
    case .denied:
        // Fall back to in-app alerts
    case .notDetermined:
        // Prompt for permission
    default:
        break
    }
}
```

---

## Notification Lifecycle

### 1. Scheduling

**When**: Immediately after session starts (Session.status = .inProgress)

**Identifier**: `session-complete-{Session.id}`

**Trigger**: 25 minutes from `Date()` (not from `Session.startedAt` to account for scheduling delay)

```swift
func scheduleSessionCompletionNotification(for session: Session) {
    let content = UNMutableNotificationContent()
    content.title = "Your tree is complete!"
    content.body = "Great work! Your tree has been saved to your forest."
    content.sound = .default
    content.categoryIdentifier = "SESSION_COMPLETE"
    content.userInfo = [
        "sessionID": session.id.uuidString,
        "notificationType": "sessionComplete"
    ]

    let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: 25 * 60,
        repeats: false
    )

    let request = UNNotificationRequest(
        identifier: "session-complete-\(session.id.uuidString)",
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request)
}
```

### 2. Cancellation

**When**:
- User abandons session (status = .abandoned)
- User completes session in foreground before notification fires
- User pauses session (cancel and reschedule with adjusted time interval)

```swift
func cancelSessionNotification(for session: Session) {
    let identifier = "session-complete-\(session.id.uuidString)"
    UNUserNotificationCenter.current().removePendingNotificationRequests(
        withIdentifiers: [identifier]
    )
}
```

### 3. Reschedule on Pause/Resume

**Pause Behavior**:
- Cancel existing notification
- Do NOT reschedule until resumed

**Resume Behavior**:
- Calculate remaining time: `25 minutes - elapsedTime - totalPausedDuration`
- Schedule new notification with adjusted trigger interval

```swift
func rescheduleAfterResume(for session: Session) {
    // Cancel old notification
    cancelSessionNotification(for: session)

    // Calculate remaining time
    let elapsedTime = Date().timeIntervalSince(session.startedAt)
    let remainingTime = (25 * 60) - elapsedTime - session.totalPausedDuration

    guard remainingTime > 0 else {
        // Session should already be complete
        return
    }

    // Schedule with remaining time
    let content = UNMutableNotificationContent()
    content.title = "Your tree is complete!"
    content.body = "Great work! Your tree has been saved to your forest."
    content.sound = .default
    content.categoryIdentifier = "SESSION_COMPLETE"
    content.userInfo = [
        "sessionID": session.id.uuidString,
        "notificationType": "sessionComplete"
    ]

    let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: remainingTime,
        repeats: false
    )

    let request = UNNotificationRequest(
        identifier: "session-complete-\(session.id.uuidString)",
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request)
}
```

### 4. Delivery

**When**: Notification fires (25 minutes after scheduled OR remaining time after resume)

**App States**:

| App State | Behavior |
|-----------|----------|
| Foreground | Notification does NOT display (app already shows completion UI) |
| Background | Notification banner appears on lock screen/notification center |
| Not Running | Notification appears; tapping opens app |

### 5. Handling Notification Tap

**Delegate Method**: `userNotificationCenter(_:didReceive:withCompletionHandler:)`

```swift
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
) {
    guard response.notification.request.content.categoryIdentifier == "SESSION_COMPLETE" else {
        completionHandler()
        return
    }

    if let sessionIDString = response.notification.request.content.userInfo["sessionID"] as? String,
       let sessionID = UUID(uuidString: sessionIDString) {
        // Navigate to forest view showing the completed tree
        navigateToForest(highlightSession: sessionID)
    }

    completionHandler()
}
```

---

## Testing Contract

### Unit Tests

**NotificationServiceTests.swift**:

```swift
@Test("Schedules notification with correct 25-minute interval")
func testScheduleNotification() async {
    let service = NotificationService()
    let session = Session()

    await service.scheduleSessionCompletionNotification(for: session)

    let pendingNotifications = await UNUserNotificationCenter.current()
        .pendingNotificationRequests()

    let notification = pendingNotifications.first { $0.identifier == "session-complete-\(session.id)" }
    #expect(notification != nil)

    guard let trigger = notification?.trigger as? UNTimeIntervalNotificationTrigger else {
        Issue.record("Expected UNTimeIntervalNotificationTrigger")
        return
    }

    #expect(trigger.timeInterval == 25 * 60)
    #expect(trigger.repeats == false)
}

@Test("Cancels notification when session is abandoned")
func testCancelNotification() async {
    let service = NotificationService()
    let session = Session()

    await service.scheduleSessionCompletionNotification(for: session)
    await service.cancelSessionNotification(for: session)

    let pendingNotifications = await UNUserNotificationCenter.current()
        .pendingNotificationRequests()

    let notification = pendingNotifications.first { $0.identifier == "session-complete-\(session.id)" }
    #expect(notification == nil)
}

@Test("Reschedules with remaining time after resume")
func testRescheduleAfterResume() async {
    let service = NotificationService()
    let session = Session()

    // Simulate session that started 10 minutes ago
    session.startedAt = Date().addingTimeInterval(-10 * 60)
    session.totalPausedDuration = 0

    await service.rescheduleAfterResume(for: session)

    let pendingNotifications = await UNUserNotificationCenter.current()
        .pendingNotificationRequests()

    let notification = pendingNotifications.first { $0.identifier == "session-complete-\(session.id)" }
    guard let trigger = notification?.trigger as? UNTimeIntervalNotificationTrigger else {
        Issue.record("Expected UNTimeIntervalNotificationTrigger")
        return
    }

    // Should schedule for remaining 15 minutes (±1 second tolerance)
    let expectedRemaining: TimeInterval = 15 * 60
    #expect(abs(trigger.timeInterval - expectedRemaining) < 1.0)
}
```

### UI Tests

**NotificationFlowTests.swift** (XCUITest):

```swift
func testCompletionNotificationFiresInBackground() {
    let app = XCUIApplication()
    app.launch()

    // Start a session
    app.buttons["Start Session"].tap()

    // Background the app
    XCUIDevice.shared.press(.home)

    // Wait for 25 minutes (or use fast-forward in test mode)
    // Verify notification appears in notification center

    // Tap notification
    // Verify app opens to forest view
}
```

---

## Error Handling

| Error Scenario | Handling |
|----------------|----------|
| Permission denied | Proceed without notification; show in-app message on completion |
| Notification scheduling fails | Log error; session still completes normally |
| Notification delivery fails | Session completion persists in SwiftData; user sees completion on next app open |
| Invalid session ID in userInfo | Graceful degradation; open app to default view |

---

## Privacy and Compliance

**Data in Notifications**:
- No personal or sensitive data in notification content
- Session ID in userInfo for navigation only (not displayed to user)
- Notification content is generic and non-identifying

**Badge Count**: Not used (badge remains nil)

**Sound**: Default system sound (respects user's notification settings)

---

## Summary

This contract ensures local notifications are:
1. Scheduled correctly with 25-minute intervals
2. Cancelled when sessions are abandoned or completed in foreground
3. Rescheduled with remaining time when paused/resumed
4. Handled gracefully when permission is denied
5. Used solely for alerting (session completion logic is independent)
