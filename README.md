# Velouria
HELLO THIS IS KIND OF IMPORTANT THIS IS ONLY FOR IOS SO FAR SO TRYING TO BUILD IT FOR ANYTHING ELSE MIGHT PROBABLY NOT WORK

Velouria is a medication tracking app for building schedules, handling reminders, and checking adherence without a lot of setup.

## Features

### Today dashboard

- Shows upcoming, taken, missed, and skipped doses for the current day
- Surfaces low-supply refill alerts
- Shows daily completion, weekly average, and streak details
- Lets the user confirm a dose, change a dose status, or edit the taken time
- Supports quick allergy and sensitivity tracking

### Medication management

- Add and edit medications
- Use RxNorm search and autofill for medication names, strengths, and forms
- Set pill counts, units per dose, refill thresholds, notes, and active/inactive state
- Add one or more dose times per medication
- Support weekly schedules and repeating every-N-days schedules
- Store per-dose timezone behavior when needed

### History and adherence

- Browse dose history by week
- Filter history by medication
- Inspect daily and weekly adherence percentages
- Review dose logs and edit past dose statuses

### Settings and behavior

- Configure missed-dose grace minutes
- Configure refill warning lead time
- Switch between following the device timezone and anchoring schedules to the original timezone
- Toggle adaptive reminder timing
- Save allergy and sensitivity keywords
- Adjust dark mode, high contrast, and text scaling

### Integrations

- Schedule and cancel local notifications for upcoming doses
- Handle timezone changes and reschedule reminders automatically
- Support Siri shortcuts and iOS widget summary updates
- Reconcile missed doses at startup and when the app resumes

## Getting Started

This project is a Flutter application.

### Run

From this folder:

```bash
flutter pub get
flutter run
```
