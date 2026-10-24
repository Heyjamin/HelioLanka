# HelioLanka iOS

Customer app for the HelioLanka solar API. A Debug run can talk to the lecturer backend.

## What you need

- Mac with Xcode 15 or newer
- iOS 17 or newer (iPhone or iPad simulator, or a signed device)
- Apple ID set as the development team in Xcode

## Lecturer backend

| | |
| --- | --- |
| API base | https://he-907259e87ef04b90924f651d03e9cf03.ecs.ap-southeast-1.on.aws |
| Health | https://he-907259e87ef04b90924f651d03e9cf03.ecs.ap-southeast-1.on.aws/health |
| Swagger | https://he-907259e87ef04b90924f651d03e9cf03.ecs.ap-southeast-1.on.aws/swagger |
| Login path | `POST /api/v1/auth/login` |

Open the health URL in a browser first. A healthy API returns `{"status":"Healthy","service":"HelioLanka.API"}`.

The app reads the base URL from `AppEnvironment.apiBaseURL`. In a **Debug** build it uses the `HELIO_API_BASE` environment variable when that variable is set. If it is not set, Debug uses the AWS URL compiled into `AppEnvironment.swift`. Release builds ignore `HELIO_API_BASE`.

## Run against the lecturer backend

1. Open the project:

```bash
open HelioLanka/HelioLanka.xcodeproj
```

2. Select the **HelioLanka** scheme (not the widget scheme).
3. Select the **HelioLanka** target → **Signing & Capabilities** → choose your **Team**.
4. Set the lecturer URL for this run:
   - **Product → Scheme → Edit Scheme…**
   - **Run → Arguments → Environment Variables**
   - Add `HELIO_API_BASE` with value `https://he-907259e87ef04b90924f651d03e9cf03.ecs.ap-southeast-1.on.aws`
5. Pick an iPhone or iPad simulator (or your device).
6. Press **Run** (Cmd+R). The Run action uses Debug, which is the configuration that reads `HELIO_API_BASE`.

## Sign in

The lecturer database is seeded with these users. Use the username, not the shared demo email.

| Username | Password | Use |
| --- | --- | --- |
| `customer` | `Customer@12345` | This iOS app |
| `admin` | `Admin@12345` | Web admin, not this app |

After the password step, the API emails a 6-digit OTP. Enter that code in the app. Staff accounts are rejected by the customer app.

## Device readings

Posting a meter reading is separate from login. The seeded installations use:

| Header | Value |
| --- | --- |
| `X-Device-Id` | Meter id, for example `MTR-000001` |
| `X-Device-Key` | `heliolanka-demo-device-key-001` |

Example:

```http
POST https://he-907259e87ef04b90924f651d03e9cf03.ecs.ap-southeast-1.on.aws/api/v1/installations/MTR-000001/readings
X-Device-Id: MTR-000001
X-Device-Key: heliolanka-demo-device-key-001
```
