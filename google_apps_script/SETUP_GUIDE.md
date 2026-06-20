# Motracker — Google Sheets Backend Setup Guide

## Step 1: Create a Google Sheet

1. Go to [Google Sheets](https://sheets.google.com)
2. Click **"Blank spreadsheet"** to create a new sheet
3. Name it **"Motracker Data"** (or whatever you prefer)
4. The sheets (Transactions, Budgets, Recurring) will be **auto-created** by the script when data is first added

## Step 2: Open Apps Script Editor

1. In your Google Sheet, click **Extensions → Apps Script**
2. This opens the Apps Script editor in a new tab
3. Delete any existing code in `Code.gs`
4. Copy the entire contents of `google_apps_script/Code.gs` from this project
5. Paste it into the Apps Script editor

## Step 3: Deploy as Web App

1. In Apps Script editor, click **Deploy → New deployment**
2. Click the gear icon ⚙️ next to "Select type" → Choose **Web app**
3. Fill in:
   - **Description**: "Motracker API"
   - **Execute as**: **Me** (your Google account)
   - **Who has access**: **Anyone** (needed for the app to call it)
4. Click **Deploy**
5. **Authorize** when prompted (click "Advanced" → "Go to Motracker" if you see a warning — it's your own script, so it's safe)
6. **Copy the Web App URL** — it looks like:
   ```
   https://script.google.com/macros/s/AKfycbx.../exec
   ```

## Step 4: Add the URL to Your App

1. Open `lib/config/constants.dart` in the Flutter project
2. Replace the placeholder URL with your actual Web App URL:
   ```dart
   static const String sheetsApiUrl = 'YOUR_WEB_APP_URL_HERE';
   ```

## Step 5: Test the API

You can test it in your browser:
```
https://script.google.com/macros/s/YOUR_ID/exec?action=getAll&email=your@email.com
```

This should return:
```json
{
  "transactions": [],
  "budgets": [],
  "recurring": []
}
```

## Updating the Script

If you need to update the script later:
1. Edit the code in Apps Script editor
2. Click **Deploy → Manage deployments**
3. Click the pencil icon ✏️ on your deployment
4. Change **Version** to **New version**
5. Click **Deploy**

## Troubleshooting

| Issue | Solution |
|---|---|
| "Authorization required" | Click Authorize and follow prompts |
| "This app isn't verified" | Click Advanced → Go to Motracker (unsafe) |
| Returns HTML instead of JSON | Make sure you deployed as "Web app", not "API executable" |
| CORS error | The Flutter app uses `http` package which doesn't have CORS issues |
