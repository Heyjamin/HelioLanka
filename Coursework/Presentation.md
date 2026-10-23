# HelioLanka — Presentation
## Implementation of the MVP, advanced iOS work, tests, and extras

**Student:** G. P. M. A. Nuwan Jeewantha  
**Module:** iOS Application Development — BSCCOMP25.1P  
**Use:** Speak this in the walkthrough or viva. The 3–5 minute recording follows `Video-Recording-Guide.md` and should stay shorter than this deck.

Each block is one slide. Bullets are what you put on the slide. The notes are what you say. Do not read the report aloud.

---

## Slide 1 — Title

**HelioLanka**  
Solar Export Intelligence  
Customer iOS app for rooftop solar in Sri Lanka

G. P. M. A. Nuwan Jeewantha  
BSC (Hons) Computing — iOS Application Development

**Say:** “HelioLanka is the customer app for someone who already has rooftop solar. It shows today’s export, recent history, the weather at the site, what that energy is worth, and a forecast that runs on the phone. I will cover the MVP, the advanced SDKs, how markers reach the API, and what sits beyond the baseline.”

---

## Slide 2 — The problem

- Readings live on a server. The customer lives on a phone.
- They want today’s kWh, an unusual day, and a rough idea of tomorrow’s income.
- Staff use the web admin. This app refuses staff roles.

**Say:** “The person I designed for checks the phone in the evening, not a dashboard at a desk. One meter, one day, one number — then the detail if they want it. If the account role is not customer, the app stops and tells them to use the web admin.”

---

## Slide 3 — MVP map

Six tabs after sign-in:

1. Home — site and today
2. History — 7 / 30 / 90 day chart
3. Weather — temperature and solar radiation
4. Earn — tariff and 30-day forecast
5. Calendar — notes, reminders, strong-sun days
6. Account — profile, map, leaderboard, Face ID, widget

**Say:** “Sign-in is username and password, then a six-digit code. After that, these six tabs are the product. Home is the daily check. History is the chart. Weather is the site forecast from my API. Earn turns kilowatt-hours into rupees. Calendar is personal notes. Account holds profile, the map, the leaderboard, and the security switches.”

---

## Slide 4 — Component 2 platform features

Submitted as the two MVP platform features:

- **User Notifications** — note reminders, a repeating daily summary, high/low generation alerts
- **Face ID / Touch ID / Optic ID** — Keychain password only after a successful prompt; OTP is still required when the session is gone

Also in the app, not used for Component 3:

- **Core Data** — 90 days of daily export, and calendar notes, SQLite, model built in code

**Say:** “I am offering notifications and biometrics as the two required platform features. Notifications are tied to real events: a note the customer saved, a daily summary at a time they picked, and a generation alert only when the latest day is far from their own recent average. Face ID never skips the server’s one-time code if the tokens are gone. The password sits in memory until they accept the prompt, then it goes to the Keychain, not UserDefaults. Core Data is also there, for the chart and the notes. I am not using Core Data, notifications, or Face ID as my advanced feature.”

---

## Slide 5 — External API

Base URL (AWS ECS, Singapore region):

`https://he-907259e87ef04b90924f651d03e9cf03.ecs.ap-southeast-1.on.aws`

- Login is two steps: password, then OTP
- Bearer token, refresh once on 401, tokens in the Keychain
- Composite site, paged readings, weather, profile, public leaderboard

**Say:** “Every customer number comes from this API. I do not call a weather vendor from the phone. The backend returns hourly weather for that installation. Tokens live in the Keychain. If a call returns 401, the client refreshes once and retries. Markers sign in with the customer account in my report. A staff login is only the blocked screen. The leaderboard GET does not send the bearer token.”

*(Have the username ready if they ask. Do not invent the OTP path.)*

---

## Slide 6 — Component 3: Core ML

On-device forecast, no cloud model:

- Features: capacity, calendar, lag 1, lag 7, 7-day mean and spread, temperature, cloud, rain, radiation
- Scaler JSON, then Core ML `SolarGenerationForecaster`
- If the model file is missing: bundled gradient-boosting trees, then a radiation heuristic
- Earn shows the engine name: `coreml`, `json-gbdt`, or `heuristic`

**Say:** “The advanced feature is an on-device solar forecast. The network only supplies weather and history. The prediction stays in the process. I standardise the features with the training scaler, then run Core ML. The Earn screen shows which engine loaded, so it is obvious this is not a hardcoded chart. Thirty forecast days drive the income figure and the widget’s tomorrow value. I am not calling ChatGPT or any other remote model. That would score zero under the brief.”

---

## Slide 7 — Component 3: WidgetKit

- App Group `group.lk.heliolanka.app`
- Snapshot: meter, site name, today kWh, tomorrow kWh
- Home writes today. Earn writes tomorrow.
- Small and medium families. Empty state if the app has never published.
- Widget does not hold a token and does not call the API

**Say:** “The second advanced feature is the Home Screen widget. A widget cannot show Face ID and should not store the session, so I publish a snapshot from Home and Earn. The extension only reads that snapshot and reloads about every thirty minutes. If you have not opened those screens, it tells you to. Small stacks the two numbers. Medium places them side by side.”

---

## Slide 8 — How a day of data moves

1. Readings pages are summed into local days
2. Core Data keeps 90 days
3. Anomaly check compares the latest day with the recent average
4. Weather hours become one feature row per day
5. Core ML forecasts 30 days
6. Snapshot updates the widget

**Say:** “This is the path I care about. Interval readings become one number per calendar day and that number is what the chart, the calendar colours, and the alert all share. Weather is rolled up the same way, one row per day, and that row is what the model sees. Nothing in the widget talks to the server.”

---

## Slide 9 — Above and beyond

- MapKit pins from installation coordinates
- EventKit write-only sync of strong-sun days
- Swift Charts on History, Weather, and Earn
- Anomaly alerts with explicit thresholds
- MVVM, actors for the API, Keychain, offline notes and history
- Public nickname is opt-in

**Say:** “Beyond the two advanced SDKs, the map plots the customer’s own sites, not a sample pin. Calendar sync only writes all-day events and does not read personal events. Charts repeat the same numbers that are already on screen as text. The leaderboard name is public only if they turn that on.”

---

## Slide 10 — iPhone and iPad

| | iPhone | iPad |
| --- | --- | --- |
| Role | Daily one-handed check | Same app, wider charts and map |
| Navigation | Bottom tabs, one column | Same tabs, cards grow with the width |
| Orientation | Portrait and landscape | Portrait, upside down, landscape |
| Biometrics | Usually Face ID | Face ID or Touch ID, same code |
| Extra format | Home Screen widget | Widget as well |

No separate split view. Chosen because the task is one customer and one meter, not a two-pane admin tool.

**Say:** “The target is universal. On iPhone the job is a bottom tab bar and a single column, plus the widget for a glance. On iPad I kept that structure. Scroll views and grids use the extra width, especially the map and the charts, and the iPad can rotate further, including upside down. I did not build a sidebar split view. A split view would not give this customer a second task to do at the same time. If I extend it, the first iPad-only change would be the chart beside the summary when the size class is regular.”

---

## Slide 11 — Tests, accessibility, documentation

- Swift Testing, not XCTest, on pure logic
- First targets: anomaly rules, formatting, forecast features, earnings maths, widget snapshot
- VoiceOver: password eye, OTP as one element, brand as one label
- Numbers exist as text beside every chart
- This report is the written documentation

**Say:** “Tests are Swift Testing, on the rules I can run without the live server: the high and low generation thresholds, formatting, the forecast feature vector, earnings multiples, and the widget snapshot. I do not unit-test the live API. For accessibility, the OTP field is one VoiceOver element, the brand image is hidden, and charts are backed by text. Large titles are still fixed sizes. I will say that plainly if you ask.”

---

## Slide 12 — What I would defend

- OTP stays a server rule. Biometrics do not replace it.
- Forecast is on device. Weather is from my API.
- Widget is a snapshot, not a second client.
- Alerts need history, so a new meter does not spam.
- One column on iPad is a product choice, not an accident I am hiding.

**Say:** “If you ask what I would change, I would fix the Home tile that says Capacity but shows the tariff, and I would let the large titles follow Dynamic Type. I would not move the forecast to a cloud API, and I would not put the session token in the widget.”

---

## Slide 13 — Close

HelioLanka  
Today’s export. Tomorrow’s forecast. On the customer’s phone.

Questions.

**Say:** “That is the submission: a customer MVP with notifications and biometrics, Core Data underneath, my own API, Core ML and WidgetKit as the advanced work, and the map, calendar, and charts around them. I can walk any file you want to open.”

---

## Timing if this deck is the live presentation

| Slides | Minutes |
| --- | --- |
| 1–3 Problem and tabs | 2 |
| 4–5 Notifications, Face ID, API | 3 |
| 6–8 Core ML, widget, data path | 4 |
| 9–11 Extras, devices, tests | 3 |
| 12–13 Defence and questions | 2 |
| **Total talk** | **about 14, then questions** |

The recorded demo is a different artefact. Keep that one inside 3–5 minutes and follow the video guide. Do not try to speak this whole deck on the recording.

## Demo backup if the network fails

- History and notes can still be on device from an earlier sync.
- The widget can still show the last snapshot.
- Say so, then retry pull-to-refresh once. Do not pretend live data loaded.
