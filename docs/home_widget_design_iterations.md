# Smoke Timer Home Widget Design Iterations

## Goal

Add a home screen widget that helps the user understand three things at a glance:

1. How long it has been since the last smoking record
2. When the next reminder is expected
3. Whether today's smoking count and spend are trending up

The widget must feel calm, readable, and utility-first. It must not glamorize smoking.

## Constraints

- The widget has to work with the data already persisted in the app.
- Flutter will provide widget data, but Android and iOS widget UI must be native.
- The design should stay useful on smaller widget sizes.
- The widget should degrade safely when there is no smoking record yet.
- Taps should open the app instead of trying to implement unsafe destructive actions from the widget surface.

## Iteration 1: Dense Status Board

### Concept

Show as many useful values as possible:

- elapsed time
- next alert
- today count
- today spend
- interval
- allowed time window

### Strengths

- High information density
- Good for power users

### Problems

- Too much text for a home screen widget
- Weak visual hierarchy
- Poor glanceability
- Hard to keep readable on iOS small size

### Decision

Rejected. Too busy for the first shipping version.

## Iteration 2: Countdown-Only Widget

### Concept

Use one large hero metric:

- elapsed minutes since last smoking record

And a small footer:

- next alert

### Strengths

- Extremely glanceable
- Strong hierarchy
- Easy to implement on Android and iOS

### Problems

- Too little context
- No daily behavior cue
- No cost context
- Empty state feels thin

### Decision

Rejected. Too minimal to justify a dedicated widget surface.

## Iteration 3: Action-Centric Widget

### Concept

Expose a primary action:

- "Open app to record now"

Alongside current status.

### Strengths

- Strong behavioral nudge
- Good conversion back into the app

### Problems

- Platform parity gets weaker
- Native widget interaction is more complex and error-prone
- Adds engineering cost without solving the main information problem

### Decision

Rejected for v1. Opening the app on tap is enough.

## Iteration 4: Schedule-Centric Widget

### Concept

Focus on reminder discipline:

- next alert time
- repeat state
- active weekdays
- allowed window

### Strengths

- Matches reminder product value
- Good for users tuning alerts

### Problems

- The most important daily question is still "how long has it been?"
- Schedule data is secondary most of the time
- More cognitive load than necessary

### Decision

Rejected as the primary layout. Keep scheduling as a support row only.

## Iteration 5: Calm Utility Summary

### Concept

A balanced widget with one primary metric and two supporting zones:

- Primary: elapsed time since last smoking record
- Secondary: next alert or scheduling state
- Tertiary: today count and today's spend

### Strengths

- Strong first-glance value
- Good utility even before opening the app
- Works well on Android and iOS
- Clear empty state
- Preserves calm, non-judgmental tone

### Problems

- Requires careful text compression
- Needs native layout tuning per platform

### Decision

Selected as the final direction.

## Final Widget Spec

## Content Priority

1. Elapsed time
2. Current status headline
3. Next alert line
4. Today count
5. Today spend

## Empty State

When no smoking record exists:

- Primary value: `첫 기록 전`
- Headline: `기록을 남기면 타이머가 시작돼요`
- Next alert: `첫 기록 후 시작`
- Footer: `오늘 0개비`

## Active State

When records exist:

- Primary value: `<N>분`
- Headline: interval status from policy
- Next alert: resolved schedule or reason it is unavailable
- Footer left: `오늘 <count>개비`
- Footer right: `지출 <amount>` or `가격 설정 필요`

## Tone

- Calm
- Practical
- Non-judgmental
- No celebratory copy
- No streak or gamification language

## Visual Rules

- Dark neutral card background
- Strong white primary metric
- Muted secondary labels
- Accent only for small status emphasis
- Rounded card shape with compact padding
- Keep text lines to a maximum of 2 in supporting sections

## Interaction Rules

- Tapping the widget opens the app
- No destructive actions from the widget
- No widget-side write actions in v1

## Platform Mapping

### Android

- Main target: resizable 4x2 style app widget
- Native UI: RemoteViews XML
- Update source: `home_widget` shared data + app-triggered refresh

### iOS

- Main target: `systemSmall` and `systemMedium`
- Native UI: WidgetKit + SwiftUI
- Shared data: App Group + `home_widget`

## Data Contract

The widget should receive the following values from Flutter:

- `elapsed_minutes`
- `elapsed_label`
- `status_title`
- `status_detail`
- `next_alert_label`
- `next_alert_value`
- `today_count_label`
- `today_spend_label`
- `has_record`
- `last_smoking_at_iso`
- `next_alert_at_iso`
- `updated_at_iso`

## Why This Final Direction Wins

- It answers the user's most important question first
- It keeps the widget readable on both Android and iOS
- It avoids risky native interactivity for v1
- It reuses existing app policy logic instead of inventing a second rules engine
- It can expand later into interactive controls without breaking the information hierarchy

## Lock Screen Iterations

### Iteration 1: Mirror the Home Widget

- Rejected because lock screen families are smaller and would truncate too aggressively.

### Iteration 2: Next Alert Only

- Rejected because it hides the core elapsed-time question users care about most.

### Iteration 3: Circular Timer Only

- Rejected because it works in `accessoryCircular` but loses too much context in rectangular and inline families.

### Iteration 4: Count and Spend Only

- Rejected because daily totals are secondary and weak on first glance.

### Iteration 5: Compressed Calm Utility

- Selected for lock screen support.
- `accessoryInline`: elapsed time plus next alert summary.
- `accessoryCircular`: compact elapsed metric with a short fallback label when no record exists.
- `accessoryRectangular`: elapsed time, current status headline, and next alert summary with one supporting daily count line.

## Lock Screen Design Rules

- Keep each family focused on one primary metric: elapsed time.
- Use scheduling data as the second line, not the headline.
- Avoid destructive or state-changing interactions from the lock screen.
- Preserve the calm, utility-first tone used by the home widget.
