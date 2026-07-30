import json
import os
import smtplib
import urllib.request
import urllib.error
from email.mime.text import MIMEText

os.environ["GMAIL_USER"] = "sujalparashar007@gmail.com"
os.environ["GMAIL_APP_PASSWORD"] = "mpdh pdnt ickl ygll"
os.environ["TEAMS_WEBHOOK_URL"] = "https://default9274ee3f94254109a27f9fb15c1067.5d.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/f65710364b934191846154e8e6917df8/triggers/manual/paths/invoke?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=ogSLKC28GyxDPcRGhXM77bd9jbtffvcIE0Op5Wd28zQ"

print("=== TESTING TEAMS WEBHOOK ===")
payload = {
    "budgetName": "LOCAL TEST",
    "threshold": 50,
    "costAmount": 25000,
    "budgetAmount": 50000,
    "currencyCode": "INR",
    "text": "Budget Alert: LOCAL TEST - 25000/50000 INR (50%)"
}
print(f"Payload: {json.dumps(payload)}")

try:
    req = urllib.request.Request(
        os.environ["TEAMS_WEBHOOK_URL"],
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"}
    )
    resp = urllib.request.urlopen(req)
    body = resp.read().decode()
    print(f"SUCCESS: HTTP {resp.status}")
    print(f"Response body: {body}")
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(f"HTTP ERROR: {e.code}")
    print(f"Response body: {body}")
except Exception as e:
    print(f"ERROR: {e}")

print()
print("=== TESTING GMAIL ===")
try:
    msg = MIMEText("Test email from FinOps function")
    msg["Subject"] = "FinOps Local Test"
    msg["From"] = os.environ["GMAIL_USER"]
    msg["To"] = os.environ["GMAIL_USER"]
    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(os.environ["GMAIL_USER"], os.environ["GMAIL_APP_PASSWORD"])
        server.send_message(msg)
    print("SUCCESS: Email sent")
except Exception as e:
    print(f"ERROR: {e}")
