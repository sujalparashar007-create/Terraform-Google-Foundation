import base64
import json
import ast
import os
import smtplib
import urllib.request
import urllib.error
from email.mime.text import MIMEText
import functions_framework

GMAIL_USER = os.environ.get("GMAIL_USER", "")
GMAIL_PASS = os.environ.get("GMAIL_APP_PASSWORD", "")
TEAMS_WEBHOOK = os.environ.get("TEAMS_WEBHOOK_URL", "")

def send_email(subject, body):
    if not GMAIL_USER or not GMAIL_PASS:
        return
    try:
        msg = MIMEText(body)
        msg["Subject"] = subject
        msg["From"] = GMAIL_USER
        msg["To"] = GMAIL_USER
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(GMAIL_USER, GMAIL_PASS)
            server.send_message(msg)
        print(f"Email sent to {GMAIL_USER}")
    except Exception as e:
        print(f"Email failed: {e}")

def send_teams(budget_name, threshold, cost, budget, currency):
    if not TEAMS_WEBHOOK:
        return
    pct = float(threshold) * 100 if threshold != "N/A" else 0
    card = {
        "type": "AdaptiveCard",
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "version": "1.4",
        "body": [
            {"type": "TextBlock", "size": "Large", "weight": "Bolder",
             "text": f"Budget Alert: {budget_name}"},
            {"type": "FactSet", "facts": [
                {"title": "Spend", "value": f"{cost} / {budget} {currency}"},
                {"title": "Threshold", "value": f"{pct:.0f}%"},
            ]},
        ]
    }
    print(f"Teams adaptive card: {json.dumps(card)}")
    try:
        req = urllib.request.Request(TEAMS_WEBHOOK, data=json.dumps(card).encode(),
                                     headers={"Content-Type": "application/json"})
        resp = urllib.request.urlopen(req)
        print(f"Teams response: HTTP {resp.status}")
    except Exception as e:
        print(f"Teams error: {e}")

@functions_framework.cloud_event
def process_budget_alert(cloud_event):
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode()
    try:
        message_data = json.loads(pubsub_message)
    except json.JSONDecodeError:
        message_data = ast.literal_eval(pubsub_message)

    bn = message_data.get("budgetDisplayName", "N/A")
    th = message_data.get("alertThresholdExceeded", "N/A")
    co = message_data.get("costAmount", "N/A")
    bu = message_data.get("budgetAmount", "N/A")
    cu = message_data.get("currencyCode", "N/A")

    print(f"Budget Alert: {bn} | Spend: {co}/{bu} {cu} | Threshold: {th}")
    send_email(f"FinOps Alert: {bn} - {co} {cu}",
               f"Budget: {bn}\nSpend: {co}/{bu} {cu}\nThreshold: {th}\n\nhttps://console.cloud.google.com/billing")
    send_teams(bn, th, co, bu, cu)
    return "OK"
