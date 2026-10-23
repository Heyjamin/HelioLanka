# HelioLanka — screen recording guide

Record one take, **3 to 5 minutes**, with **your voice**. The coursework wants you describing the features, not background music and not a silent screen.

This is the recording you upload. It is not the live viva. The viva is a separate question session.

Aim for **about 4 minutes 15 seconds**. If you rush the forecast, you will drop the part that carries the advanced-SDK marks.

---

## Before you record

1. Use a **real customer account** that has a meter, readings, coordinates, and weather. Rehearse the login once so you know where the OTP arrives. Fill that same account into section 5 of the report.
2. Simulator or device: iPhone size first (for example iPhone 16). Dark appearance is what the app forces. Enroll Face ID on the simulator if you will show it: **Features → Face ID → Enrolled**.
3. Start **signed out**, so the recording includes the password step. You can show Face ID in the last minute if it is already enabled on a second launch. If Face ID is awkward on the day, show the Account switch and say the prompt appears after OTP. Do not spend a minute fighting the simulator.
4. Notifications: on the simulator, accept the permission alert the first time you save a reminder or turn on the daily summary. If you already denied it, reset the simulator or enable notifications in Settings before you record.
5. Widget: add the HelioLanka widget to the Home Screen **before** the take if adding it live costs too much time. You will cut to the Home Screen near the end. Open Home and Earn once before the take as well, so the snapshot is not empty — then still open them on camera so the marker sees the numbers match.
6. Hide personal email if the OTP screen shows a real address you do not want published. The app already masks it. Do not read the password aloud.
7. Xcode: stop the debugger console from covering the app. Record the Simulator window only (QuickTime → File → New Screen Recording, or the Simulator’s record control). Leave the menu bar out if you can.
8. Phone on silent except your microphone. Close notifications from other apps.
9. Speak in full sentences. Name the tab, then say what the number means.

### If the API is down

Do not pretend. Say “the service did not answer, this is the error line the app shows,” show the message, and move to anything already stored (history, notes, widget snapshot). A honest failure is better than a frozen screen with no narration.

---

## Shot list

Speak the lines in your own accent. The words in **bold** are the idea that must be heard. You can shorten a sentence. Do not skip a shot.

| Time | Screen | What you do | What you say |
| --- | --- | --- | --- |
| 0:00–0:20 | Sign in | Show the HelioLanka mark and the form. Do not linger on the password. | “This is HelioLanka, for a rooftop solar customer in Sri Lanka. Sign-in is the account on our API: username and password, then a one-time code. Staff accounts are turned away. This recording uses a customer meter.” |
| 0:20–0:45 | OTP | Enter the 6-digit code and tap Verify. If the Face ID offer appears, tap **Not now** for this take so you reach the tabs quickly. You will show biometrics later. | “The server does not open a session on the password alone. It sends a code. Tokens are stored in the Keychain only after this step. I am skipping the Face ID offer for a moment so I can show the product first.” |
| 0:45–1:15 | Home | Point at the site name, province line, the big Today figure, live power, last interval, cumulative, and the recent rows. Pull to refresh once if it is fast. If you have two meters, open the meter menu and switch, then switch back. | “Home is today’s site. The name, the province and substation, and today’s export are the sum of this meter’s intervals. Live power and the last reading come from the installation composite. Changing the meter reloads this screen. These figures are what the widget will show as today.” |
| 1:15–1:40 | History | Switch 7D, 30D, and 90D. Point at the chart and the total. | “History keeps daily totals in Core Data, up to ninety days. The chart is the same stored days. Seven, thirty, and ninety are suffixes of that list. This is local persistence, not the advanced feature I am submitting.” |
| 1:40–2:05 | Weather | Show today’s temperature, the temperature line, the radiation bars, and one outlook row. | “Weather is hourly data for this installation from our API, not from a second weather app on the phone. Temperature and shortwave radiation are what the forecast uses. The list under the charts repeats the numbers as text.” |
| 2:05–2:45 | Earn | Leave “Use history average” and “Use site tariff” on. Point at the engine name under “30-day forecast”, the predicted kWh, the income, and the chart. | “Earn turns history and the site tariff into rupees. The thirty-day chart is the on-device model. The label under the title is the engine that actually ran — Core ML, or the bundled tree model if Core ML did not load. Weather came from the API. The prediction does not. I am not calling a cloud AI. Tomorrow’s first bar is the number the widget stores.” |
| 2:45–3:25 | Calendar | Move one month, tap a day that has export, show the kWh. Save a short note with a reminder if permission is ready. Tap “Sync high-generation days” only if you are happy for those events to land on the simulator calendar. Turn the daily summary on and show the time. | “The calendar paints high-generation days from the same stored totals. A note can schedule a local notification. The daily summary is a repeating local notification, default six in the evening. High and low alerts fire only when the latest day is well away from the recent average, so a new meter does not spam. Sync writes all-day events. It does not read the rest of the calendar.” |
| 3:25–3:50 | Account | Open Map and show the pin. Go back. Open Leaderboard and switch Day / Week / Month. Go back. Show the Face ID switch and the widget switch. | “The map pins are this customer’s installations, using the coordinates from the API. The leaderboard is a public read. The Face ID switch stores the password in the Keychain only after a successful biometric prompt, and it still does not skip the one-time code when the session is gone. The widget switch does not put a token in the widget.” |
| 3:50–4:15 | Home Screen widget | Leave the app. Show the small or medium widget. Read the two numbers. If you have time, open the app again and show Home’s today figure beside the widget. | “This is WidgetKit. Today is the export from Home. Tomorrow is the on-device forecast from Earn. The widget reads an App Group snapshot. It never calls the API. That is the advanced pair I want marked: Core ML, and this widget. The same app runs on iPad as one column with wider charts. I kept a single tab bar because the task is one meter, not a split admin screen.” |

Stop by **4:30** even if a sentence is unfinished. Cut in the editor rather than running past 5:00.

---

## What the marker should hear at least once

Say these phrases somewhere in the take. They map to the marks:

- “one-time code” and “Keychain”
- “User Notifications” or “local notification” for a note or the daily summary
- “Face ID” or “Touch ID”
- “Core Data” for the ninety-day history
- “our API” and the idea that weather and readings are not hardcoded
- “on-device” and “Core ML” on the Earn screen, including the engine name you actually see
- “widget” and “it does not call the API”
- one sentence on iPhone versus iPad

If the engine name on Earn says `heuristic`, say that the Core ML file did not load in this build and the screen is showing the fallback. Do not say “this is Core ML” if the label says otherwise. Check this in rehearsal.

---

## What to leave out

- Do not tour Xcode or the file tree in this video. The viva can open files.
- Do not read the report.
- Do not show the register form unless login is broken. Registration is easy to mistype on camera.
- Do not demonstrate a staff login unless you have spare time inside five minutes. One sentence is enough.
- Do not open Settings and scroll. The Account switches are enough.
- Do not film the OTP email inbox if it shows other messages.

---

## Rehearsal pass (do this once, do not submit it)

Time yourself with the shot list. Note the clock at Earn and at the widget.

| Checkpoint | You should be near |
| --- | --- |
| Tabs visible | 0:45 |
| Earn engine name spoken | 2:20 |
| Widget visible | 4:00 |
| End | 4:15 to 4:40 |

If you are past 3:00 before Earn, you talked too long on Home. Cut the meter-switch demo.

---

## Export

- Resolution: 1080p if the tool allows, otherwise the simulator’s native size. The text “coreml” must be readable.
- Format: MP4 or the LMS’s accepted type.
- File name: `HelioLanka-Demo-YourName.mp4`
- First frame: the sign-in screen, not the Xcode window.
- Audio: your narration, louder than any keyboard noise.

Watch the file once with sound before you upload. Confirm the engine name, the widget numbers, and that you did not say a password.

---

## Optional second clip — only if the lecturer allows extra files

The brief asks for **one** narrated recording. Do not rely on a second clip. If you want iPad in the same file, use the last sentence of the widget shot, or add **20 seconds** at the end: rotate an iPad simulator, show History’s chart wider, and say you did not add a split view. Drop the calendar reminder instead if you are about to pass 5:00. Earn and the widget stay. They are the advanced marks.
