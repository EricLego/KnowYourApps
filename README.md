# KnowYourApps - Digital Wellbeing Monitor

KnowYourApps is a cross-platform Flutter application that helps you understand how your app usage patterns may influence your mood and overall digital wellbeing.

## Features

### 🔍 App Usage Tracking
- Track which apps you use and for how long
- Automatic categorization of apps (Social, Productivity, Entertainment, etc.)
- Daily, weekly, and monthly usage stats

### 📊 Interactive Visualizations 
- App usage breakdown by category
- Daily usage patterns
- Mood trends over time

### 🧠 Mood Analysis
- AI-powered mood predictions based on your app usage
- Rate your mood and provide feedback
- Identification of apps with positive and negative impact

### 🏷️ Custom Categories
- Create and customize app categories
- Manual override for app categorization
- Personalize your tracking experience

## Tech Stack

- **Frontend**: Flutter, Provider for state management
- **Local Storage**: SQLite (sqflite)
- **App Usage Tracking**: Native APIs (UsageStatsManager for Android, ScreenTime API for iOS)
- **Visualization**: FL Chart
- **ML**: TensorFlow Lite with on-device processing

## Privacy & Security

- All data is stored locally on your device
- No data is sent to remote servers
- You have complete control over your data
- Can export or delete all data at any time

## Requirements

- **Android**: Version 7.0 (API level 24) or higher
- **iOS**: iOS 13 or higher
- **Permissions**: App usage stats permission (will be requested at startup)

## Getting Started

### Installation

1. Download the app from the App Store or Google Play Store
2. Launch the app and follow the onboarding process
3. Grant necessary permissions when prompted
4. Start tracking your app usage and mood

### First Steps

1. Allow 1-2 days for the app to collect usage data
2. Rate your mood regularly for better insights
3. Check the Insights tab to see patterns emerging
4. Customize categories if needed in the Categories tab

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/knowyourapps.git

# Navigate to the project folder
cd knowyourapps

# Get dependencies
flutter pub get

# Run in debug mode
flutter run
```

### Project Structure

```
lib/
├── models/       # Data models
├── views/        # UI components
│   ├── screens/  # Full screens
│   └── widgets/  # Reusable UI components
├── controllers/  # State management
├── services/     # Business logic
└── main.dart     # Entry point
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

If you have questions or feedback, please create an issue on our GitHub repository or contact us at support@knowyourapps.com