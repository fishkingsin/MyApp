# MyApp Constitution

<!--
Sync Impact Report:
Version Change: Initial → 1.0.0
Constitution Type: Initial ratification (MAJOR)
Modified Principles: N/A (initial creation)
Added Sections:
  - Core Principles (5 principles: Radical Simplicity, Test-First Development, 60fps Performance, Cold Start Performance, Accessibility)
  - Performance Standards
  - Development Workflow
  - Governance
Templates Status:
  - ✅ plan-template.md: Constitution Check section compatible
  - ✅ spec-template.md: User Scenarios align with simplicity principle
  - ✅ tasks-template.md: Test-first workflow compatible
  - ✅ checklist-template.md: No conflicts
Follow-up TODOs: None
-->

## Core Principles

### I. Radical Simplicity & Offline-First

MyApp MUST remain radically simple, embodying the Forest focus app philosophy: minimal UI, essential features only, zero complexity creep. The app MUST function completely offline—no network requests, no cloud sync, no external dependencies. All data persists locally using SwiftUI's native persistence mechanisms (UserDefaults for simple state, CoreData or file-based storage for complex data).

**Rationale**: Users choose focus apps to escape digital complexity and distractions. Network dependencies introduce latency, failure modes, privacy concerns, and cognitive overhead. Offline-first ensures reliability, speed, privacy, and zero distractions.

**Non-Negotiable Rules**:
- NO feature additions without removing equivalent complexity elsewhere
- NO network requests or external service integrations
- NO user accounts, authentication, or cloud sync
- NO third-party SDKs except Apple frameworks
- Features MUST be justifiable as essential to the core focus experience
- UI MUST use native SwiftUI components without custom chrome or decoration
- Settings MUST be minimal (prefer smart defaults over configuration)

### II. Test-First Development (TDD)

All code changes MUST follow strict Test-Driven Development: write tests → tests fail → implement → tests pass → refactor. Tests are written BEFORE implementation begins, ensuring every feature is testable by design and requirements are understood before coding starts.

**Rationale**: TDD prevents regression bugs, documents intended behavior, forces simple interfaces, and ensures requirements clarity before implementation investment. For a focus app, reliability is paramount—bugs break user trust and destroy the calm experience.

**Non-Negotiable Rules**:
- Tests MUST be written before implementation code
- Tests MUST fail initially (red phase required)
- Implementation proceeds only after test failures are confirmed
- Tests MUST pass before code review or merge
- Use Swift Testing framework (`import Testing`) for unit tests
- Use XCTest for UI tests with XCUIApplication
- Test coverage MUST include: happy paths, edge cases, error states
- Refactoring MUST not break existing tests (green phase maintained)

### III. 60fps Performance

All animations and UI interactions MUST maintain 60 frames per second (16.67ms per frame) on the minimum supported iOS version and device. Performance degradation below 60fps is a critical bug that MUST be fixed before release.

**Rationale**: Smooth animations are essential to the calm, focused experience. Janky UI creates stress and breaks user immersion. A focus app must feel fluid and responsive to support flow states.

**Non-Negotiable Rules**:
- All SwiftUI animations MUST profile at 60fps using Instruments
- No main thread blocking operations (network, disk I/O, heavy computation)
- Use background queues for any work exceeding 10ms
- Profile with Instruments Time Profiler for every animation-heavy feature
- Test on minimum supported device (e.g., iPhone 12 or oldest iOS target)
- SwiftUI view hierarchies MUST remain shallow (avoid deep nesting)
- Lazy loading MUST be used for lists and grids (LazyVStack, LazyHStack, LazyVGrid)

### IV. Cold Start Performance (<2s)

App MUST launch to interactive state in under 2 seconds from cold start on the minimum supported device. This includes app initialization, data loading, and rendering the first interactive screen.

**Rationale**: Fast launch removes friction from focus sessions. Users should tap the icon and immediately begin working. Slow launches create abandonment and break the intention to focus.

**Non-Negotiable Rules**:
- Cold start MUST complete in <2 seconds (tap to interactive)
- Measure with Instruments App Launch template on minimum device
- Defer non-critical initialization until after first screen renders
- Use lazy loading for assets and data not needed immediately
- Optimize @main app initialization (minimize work in init/body)
- Test cold start after device restart (no OS caching)
- Avoid heavy CoreData model loading on launch (defer or paginate)

### V. Accessibility (VoiceOver & Dynamic Type)

All UI elements MUST be fully accessible via VoiceOver with clear, descriptive labels. All text MUST scale correctly with iOS Dynamic Type settings (minimum: Accessibility Extra Large). Accessibility is not optional—it MUST be validated before every release.

**Rationale**: Focus tools should serve all users, including those with visual impairments or who prefer larger text. Accessibility is both a legal requirement and a moral obligation. Well-labeled UI also improves testability and UI test automation.

**Non-Negotiable Rules**:
- Every interactive element MUST have an accessibility label
- VoiceOver navigation MUST be logical (top-to-bottom, left-to-right)
- Custom controls MUST use accessibility traits (button, header, etc.)
- All text MUST use Dynamic Type (.body, .title, etc.—no fixed font sizes)
- Test with VoiceOver enabled (Simulator: Cmd+Fn+F5)
- Test with Accessibility Inspector in Xcode
- Test at Accessibility Extra Large text size
- Color contrast MUST meet WCAG AA standards (4.5:1 for normal text)

## Performance Standards

**Gate**: All features MUST meet these performance benchmarks before code review approval.

| Metric | Target | Measurement Tool |
|--------|--------|------------------|
| Cold Start | <2s | Instruments App Launch |
| Animation Framerate | 60fps | Instruments Core Animation |
| View Render Time | <16ms | SwiftUI View Body profiling |
| Memory Usage (Idle) | <50MB | Instruments Allocations |
| Battery Impact | Low | Xcode Energy Gauge |

## Development Workflow

**Gate**: All code changes MUST follow this workflow without exception.

1. **Write Tests** (Red Phase)
   - Draft test cases covering happy path, edge cases, errors
   - Tests MUST compile and fail (red phase)
   - Get test approval from team/stakeholder before implementation

2. **Implement Feature** (Green Phase)
   - Write minimal code to make tests pass
   - No gold-plating or speculative features
   - Tests MUST pass (green phase)

3. **Refactor** (Blue Phase)
   - Improve code clarity and structure
   - Tests MUST remain passing
   - Profile performance if animation or launch-time code

4. **Accessibility & Performance Validation**
   - Run VoiceOver through all new screens
   - Test Dynamic Type at Extra Large size
   - Profile with Instruments if performance-critical
   - Verify 60fps and <2s cold start maintained

5. **Code Review**
   - All tests passing
   - Performance benchmarks met
   - Accessibility validated
   - Complexity justified (if any added)

## Governance

**Constitution Authority**: This constitution supersedes all other development practices, team preferences, and external style guides. When conflicts arise, constitution principles take precedence.

**Amendment Process**:
- Amendments require written proposal with rationale
- Breaking changes (removing/weakening principles) require team consensus
- Additions (new principles) require demonstration of need via incident retrospective or blocked feature
- All amendments MUST update this document and increment version per semantic versioning

**Versioning Policy**:
- **MAJOR**: Backward incompatible changes (removing principles, weakening requirements)
- **MINOR**: New principles or sections added, material expansions
- **PATCH**: Clarifications, typo fixes, non-semantic improvements

**Compliance Enforcement**:
- All PRs MUST verify compliance with constitution principles
- Code reviewers MUST reject PRs violating constitution without exception
- Constitution violations discovered post-merge MUST be reverted or fixed immediately
- Use `.specify/templates/plan-template.md` for Constitution Check gates during planning
- Use CLAUDE.md for runtime development guidance specific to this iOS project

**Complexity Justification**:
- Any feature adding complexity MUST document justification in plan.md Complexity Tracking table
- Simpler alternatives MUST be considered and explicitly rejected with reasoning
- Default answer to "Should we add this?" is NO unless essential to focus experience

**Version**: 1.0.0 | **Ratified**: 2026-01-11 | **Last Amended**: 2026-01-11
