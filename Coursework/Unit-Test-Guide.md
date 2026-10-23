# Unit test guide — write these yourself

This guide is a plan for the Swift Testing target the coursework asks for (Component 4). It is not a test file to paste into the project.

The module rule is that an LLM must not generate the executable code you submit. Use this document as a checklist. You type the test functions, you choose the names, and you run them until they pass. Then update section 7 of `Final-Report.md` with the real test count and a screenshot.

Do not add these tests by asking an assistant to edit the Xcode project. The steps below are done by you in Xcode.

---

## 1. What you are testing

Test **rules you can run with no network**. Do not call the live API from a unit test. A lab machine with no login would fail for the wrong reason.

Test these types. They are already in the app and they do not need a server:

| Type | Why it is a good test |
| --- | --- |
| `GenerationAnomalyEvaluator` | Pure function. Thresholds are the alert feature. |
| `HelioFormat` | Customers see `kWh` and `LKR`. Nil must not crash. |
| `UserMe` | Role check, display name, and meter list drive sign-in and the meter picker. |
| `SolarForecastModel.featureVector` | The Core ML input. Static, no model file required. |
| `SolarForecastModel.dailyWeatherFeatures` | Turns hourly API rows into one row per day. |
| `EarnViewModel` | Earnings maths: history switch, tariff switch, 30/90/365. |
| `WidgetSnapshot` | The widget’s only input. Encode and decode it. |
| `CalendarViewModel.daysInMonth` | Monday-first month grid. |
| `APIError` | The sentence the customer sees. |

Leave these **out** of the unit-test target:

- `APIClient` against the real host
- Face ID (the simulator prompt is not a unit test)
- `UNUserNotificationCenter` and `EKEventStore`
- SwiftUI view layout

You can describe those in the report as manual checks. They are not stable unit tests.

---

## 2. Add the target in Xcode

1. Open `HelioLanka.xcodeproj`.
2. File → New → Target…
3. Choose **Unit Testing Bundle**. Name it `HelioLankaTests`.
4. Set **Host Application** to `HelioLanka`. This lets `@testable import HelioLanka` see internal types, and it lets `Bundle.main` see the model files if you later test a real prediction.
5. Language: Swift. Finish.
6. If Xcode created an `XCTest` template file, delete that file from the test target. This module wants **Swift Testing**, not XCTest. Do not keep `import XCTest` and `XCTestCase` in the file you submit.
7. File → New → File… → Swift File, inside `HelioLankaTests`. One file per area is enough, for example:
   - `AnomalyTests.swift`
   - `FormatTests.swift`
   - `ForecastFeatureTests.swift`
   - `EarningsTests.swift`
   - `SnapshotTests.swift`
8. Each file starts with:

```swift
import Testing
@testable import HelioLanka
```

9. Product → Test, or Command–U. The diamond in the gutter runs one function.
10. The scheme must include the test target. Edit Scheme → Test → tick `HelioLankaTests` if it is missing.

A Swift Testing function looks like this. The example is a dummy check so you can see the shape. Replace it with the cases in section 4. Do not submit the dummy.

```swift
import Testing

@Test func twoPlusTwo() {
    #expect(2 + 2 == 4)
}
```

Use `#expect` for a check that should be true. Use `#require` when the next lines are meaningless if the value is missing (it stops that test).

View models are `@MainActor`. Put `@MainActor` on those test functions, or on the struct that holds them:

```swift
@MainActor
struct EarningsTests {
    @Test func example() { }
}
```

`GenerationAnomalyEvaluator` and `HelioFormat` do not need the main actor.

---

## 3. How to build a `DailyGeneration` row

`evaluate` sorts by `dayStart` and uses the last row as “today”. Build four or more days in order. Any increasing dates are fine. A simple pattern:

- Day 0 = `Date(timeIntervalSince1970: 1_700_000_000)`
- Each next day = previous plus `86_400` seconds

`DailyGeneration` needs a `key`, `meterId`, `dayStart`, and `exportKwh`. The evaluator only reads `dayStart` and `exportKwh`. Use any key and meter id.

---

## 4. Cases to implement

Write one `@Test` per row. The name should say the situation, for example `latestDayFarAboveRecentAverageIsHigh`.

### 4.1 Generation alerts

Constants in `GenerationAnomalyEvaluator` (read them again before you assert, in case you have edited them):

- High if latest ≥ max(baseline × 1.35, baseline + 3)
- Low if latest ≤ min(baseline × 0.55, baseline − 2.5)
- Need at least 4 days in the array
- Latest export must be greater than 0.05
- At least 3 earlier days must be greater than 0.05
- Baseline (mean of those earlier days, up to 14) must be at least 2

| Situation | Export values, oldest → newest | Expect |
| --- | --- | --- |
| Too few days | 10, 10, 10 | `nil` |
| Latest almost zero | 10, 10, 10, 0 | `nil` |
| Baseline under 2 | 1, 1, 1, 8 | `nil` |
| Normal day | 10, 10, 10, 10 | `nil` |
| High day | 10, 10, 10, 20 | kind `.high`, export 20, baseline 10 |
| Low day | 10, 10, 10, 4 | kind `.low`, export 4, baseline 10 |

Check the arithmetic yourself before you lock the assertion:

- Baseline of 10, 10, 10 is 10.
- High bar is max(13.5, 13) = 13.5. 20 is above it.
- Low bar is min(5.5, 7.5) = 5.5. 4 is below it.
- 10 is inside both bars, so the normal day is `nil`.

Also assert the alert’s `day` equals the last row’s `dayStart`.

Add one more test where the latest day is only slightly high, for example 10, 10, 10, 12. 12 is below 13.5, so the result must be `nil`. That is the edge that stops a noisy notification.

### 4.2 Formatting

| Call | Expect |
| --- | --- |
| `HelioFormat.energyKwh(nil as Double?)` | the string `- kWh` |
| `HelioFormat.powerKw(nil)` | the string `- kW` |
| `HelioFormat.energyKwh(1.5)` | contains `kWh` |
| `HelioFormat.currency(10)` | has prefix `LKR ` |
| `HelioFormat.amount(-4, fractionDigits: 2)` | does not crash; two digits after the decimal separator |

Run `currency(1234.5)` once, look at the string, and assert that exact string in a second test so grouping stays stable. `en_LK` is the locale in `HelioFormat`. Do not assert a US-only format you guessed.

### 4.3 User

Build a `UserMe` in the test. You need every stored property the struct declares (`username`, `email`, `firstName`, `lastName`, `phone`, `role`, province/district/substation codes, linked meter and account, `linkedAccounts`, `isActive`, `lastLoginAtUtc`). Use nil where the type is optional.

| Situation | Expect |
| --- | --- |
| `firstName` and `lastName` empty | `displayName` equals `username` |
| `firstName` `"Nuwan"`, `lastName` `"Jeewantha"` | `displayName` equals `Nuwan Jeewantha` |
| `role` `"Customer"` | `isCustomer` is true |
| `role` `"Admin"` | `isCustomer` is false |
| Two linked accounts, one meter each | `allMeters.count` is 2 |
| `linkedAccounts` nil | `allMeters` is empty |

### 4.4 Forecast features

`featureVector` is static. You do not need the Core ML file for these tests.

Use a fixed `Date`, a capacity of 5, and a `WeatherDayFeatures` you fill in (or the defaults: 28 °C, 55% cloud, 75% humidity, 2 mm, 220 W/m²).

| Situation | Expect |
| --- | --- |
| `history` empty | `lag_1_kwh` is 6 (the code’s default) and `lag_7_kwh` is the same |
| `history` is `[4, 5, 6]` | `lag_1_kwh` is 6 and `lag_7_kwh` is 6, because there is no seventh-from-last day |
| `history` has 7 values | `lag_7_kwh` is the first of those seven, `lag_1_kwh` is the last, `rolling_7_mean_kwh` is their average |
| One-value history | `rolling_7_std_kwh` is 1.2 |
| Capacity argument 5 | `capacity_kwp` is 5 |
| Any day | `day_of_week` is an integer from 0 through 6 |
| A Monday you construct with `Calendar` | `day_of_week` is 0. The code uses `(weekday + 5) % 7` because training treated Monday as 0, and Apple’s weekday uses Sunday as 1 |

`dailyWeatherFeatures`:

| Situation | Expect |
| --- | --- |
| Empty hourly array | empty result |
| Two `WeatherPoint`s on the same local day, temps 20 and 30, rain 1 and 2 | one day, average temp 25, precipitation 3 |
| A point with all weather fields nil | that day uses the defaults 28, 55, 75, and 220, and rain 0 |

`WeatherPoint` needs `timeUtc` plus the optional doubles. Humidity is not on `WeatherPoint`. The feature row always uses 75. Assert that.

Optional, after the feature tests pass: construct `SolarForecastModel()` and forecast 7 days with a short history. Assert you got 7 rows, every `predictedKwh` is ≥ 0, and `engineName` is one of `coreml`, `json-gbdt`, `heuristic`. With the app as host, you should see `coreml` if the compiled model is in the app bundle. If you see `heuristic`, the model file is not in that target — say so in the report rather than forcing the test to lie.

### 4.5 Earnings

`EarnViewModel` needs a `SessionManager()`. Creating one does not hit the network. The test must be `@MainActor`.

Set properties, then read `effectiveAvg`, `effectiveRate`, and `projections`. Do not call `load()`.

| Setup | Expect |
| --- | --- |
| `useHistoryAverage = true`, `historyAverage = 8`, `avgKwhPerDay = 99` | `effectiveAvg` is 8 |
| `useHistoryAverage = true`, `historyAverage = nil`, `avgKwhPerDay = 12` | `effectiveAvg` is 12 |
| `useHistoryAverage = true`, `historyAverage = 0`, `avgKwhPerDay = 12` | `effectiveAvg` is 12 (zero history does not count) |
| `useHistoryAverage = false`, `avgKwhPerDay = -5` | `effectiveAvg` is 0 |
| `useTariffFromSite = true`, `tariffFromSite = 22.5`, `unitRateLkr = 1` | `effectiveRate` is 22.5 |
| `useTariffFromSite = false`, `unitRateLkr = 10` | `effectiveRate` is 10 |
| Average 10, rate 20 | projections: 1 day → 10 kWh and 200 LKR; 30 → 300 and 6,000; 90 → 900 and 18,000; 365 → 3,650 and 73,000 |
| `forecastDays` set to two days of 4.0 and 6.0, rate 10 | `forecastMonthKwh` is 10 and `forecastMonthIncome` is 100 |

`EarningsProjection.id` is the label. The four labels are `per day`, `30 days`, `90 days`, `365 days`.

### 4.6 Widget snapshot

| Situation | Expect |
| --- | --- |
| Encode `WidgetSnapshot.preview`, decode it | equal to the value you encoded |
| `WidgetSnapshot.empty` | `updatedAt` is `.distantPast` |
| A hand-built snapshot | `meterId`, both kWh figures, and `installationName` survive the JSON round trip |

Use `JSONEncoder` and `JSONDecoder`. This is the contract `WidgetSnapshotStore` depends on.

### 4.7 Calendar grid

`CalendarViewModel` is `@MainActor` and needs a `SessionManager()`.

Set `monthCursor` to the first of a month you pick, then read `daysInMonth`.

Assert:

- `daysInMonth.count % 7 == 0`
- the non-nil dates are all in that month
- the first non-nil date is day 1
- the number of non-nil cells equals the number of days in that month
- the number of leading nils equals `(weekday of the 1st + 5) % 7` using `Calendar.current`

Then set no generation data and call `isHighGeneration` on that day. Expect false.

Insert one entry in `generationByDay` for a day, set `highGenerationThreshold` to 10, and check `kwh(on:)` and `isHighGeneration` both above and below 10.

Do not call `load()`, `saveNote()`, or `syncHighGenToDeviceCalendar()` in a unit test. Those talk to the network, Core Data, notifications, or EventKit.

### 4.8 Errors

| Case | `errorDescription` |
| --- | --- |
| `APIError.unauthorized` | `Session expired. Please sign in again.` |
| `APIError.invalidURL` | `Internal server error, please try again later.` |
| `APIError.http(status: 500, message: "Busy")` | `Busy` |

---

## 5. When a test fails

- Read the line you wrote and the function it calls. Do not “fix” the test by weakening it until a bug disappears.
- If a forecast number surprises you, check whether you asserted the engine’s output instead of the feature vector. Feature tests should not depend on Core ML weights.
- If `@testable import HelioLanka` fails, the test target is not depending on the app target, or the host is wrong.
- If a `@MainActor` view model warns, mark the test `@MainActor`.
- If Command–U runs XCTest only, the new files are not in `HelioLankaTests`, or the scheme’s Test list is missing that target.

---

## 6. What “done” looks like

- Command–U is green on a simulator.
- There is no `import XCTest` in the files you added.
- Every test in section 4 exists, including the edge rows (too few days, zero history average, negative kWh clamped to 0, Monday = 0).
- You can explain, without reading this guide, why 20 kWh is high and 12 kWh is not, when the previous days were 10.

Then edit the report:

- Delete the sentence that says the test target is not in the project yet.
- Write the test count, the date, and the simulator.
- Keep one screenshot of the green Test navigator for your notes. You do not have to embed it if the LMS only takes the PDF, but have it for the viva.

---

## 7. Accessibility checklist (same component, not a unit test)

The report already describes what the app does today. Before you submit, check these yourself on the simulator (Accessibility Inspector, or Settings → Accessibility → VoiceOver). Do not treat this list as code to paste.

Already in the project, so you should be able to hear them:

- Password button: “Hide password” / “Show password”
- OTP: one element, “One-time code, n of 6 digits”
- Brand lockup: one label, the image hidden
- Account toggles and tab labels spoken as their titles
- Chart screens also show the figure as text

Worth doing with your own edits if you want the accessibility marks to be safer:

- Turn on larger Dynamic Type and look at Home, History, and Earn. Titles at a fixed 28 pt and 40 pt will not grow. Text that uses `.headline` and `.body` will. If a title is clipped, change that one font to a text style.
- VoiceOver the History chart, then the “Daily totals” list under it. You should reach the numbers without the chart.
- Calendar chevrons are 44 pt. Give each a label such as “Previous month” and “Next month” if VoiceOver only says “button”.
- Confirm the gold “high generation” state is also a sentence (“Recorded export: …”) when the day is selected.

Forced dark mode is a product choice (`.preferredColorScheme(.dark)`). Say that in the viva. Do not claim a light-mode appearance you cannot show.

---

## 8. Commenting the tests

A short comment above a test is enough when the threshold is not obvious. Example of the kind of sentence to write in your own words: why three earlier days are required, or why humidity is 75. Do not comment `// checks the value`.
