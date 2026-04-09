# Bean.ai – Your AI Coffee Companion & Personal Barista

A premium, AI-powered coffee tracker, brew optimizer, and discovery tool built with Flutter for iOS and Android. Designed for specialty coffee enthusiasts and home baristas who want to maximize flavor, track their journey, and discover new favorites.

## Features

### Smart Bean Scanner & Library
- Point your camera at any coffee bag and let AI vision extract brand, origin, roast level, varietal, tasting notes, and more
- Build a digital stash with roast date tracking and freshness indicators
- Inventory alerts when beans are aging past peak
- Cost-per-cup calculator
- Pantry view: fresh vs. aging at a glance

### AI Brew Optimizer
- Input your equipment (grinder, brewer, water, etc.) and flavor preferences
- AI generates precise recipes tailored to each bean: dose, ratio, temperature, grind, timing
- Log brews with one tap, rate them, and get AI feedback
- Pattern analysis: "You prefer lighter roasts from Africa—here's why your last Kenyan was flat"

### Flavor Journal & Insights
- Professional tasting note templates with SCA-style scoring (aroma, acidity, sweetness, body, balance, aftertaste, cleanliness)
- Interactive radar charts visualizing your palate
- AI summarizes your preferences over time
- Track improvement with brew success streaks and consistency scores

### Discovery & Subscription Helper
- AI-curated roaster and bean recommendations based on your taste profile
- Track multiple bean subscriptions in one dashboard
- Community insights: see what others brewed with the same bean
- Bean of the Week personalized picks

### Premium Subscription ($4.99/month)
- Unlimited scans and brew logs
- Advanced AI coaching and feedback
- Full palate insights and analytics
- Weekly personalized Bean of the Week
- Export journals, dark mode, widget support

## Tech Stack

- **Framework**: Flutter 3.x (Dart)
- **State Management**: Provider + ChangeNotifier
- **Navigation**: go_router (declarative, deep-link ready)
- **Local Storage**: Hive (fast, lightweight NoSQL)
- **AI Backend**: Cloud AI APIs (GPT-4V / Gemini Pro Vision for scanning, LLMs for coaching)
- **Charts**: fl_chart (radar, pie, bar, line)
- **Camera**: image_picker + camera package
- **In-App Purchases**: RevenueCat (purchases_flutter)
- **Backend**: Firebase (Auth, Firestore, Storage, Analytics, Cloud Messaging)
- **Design System**: Material 3 with custom coffee-themed palette

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── config/
│   ├── theme.dart               # Coffee-themed light/dark themes
│   ├── constants.dart           # App constants, flavor wheel, brew methods
│   └── routes.dart              # go_router configuration
├── models/
│   ├── bean.dart                # Bean model with freshness tracking
│   ├── brew.dart                # Brew log model with recipe data
│   ├── tasting_note.dart        # Tasting note with SCA scoring
│   ├── user_profile.dart        # User, equipment, preferences, stats
│   └── roaster.dart             # Roaster and subscription models
├── services/
│   ├── ai_service.dart          # AI API integration (scan, recipes, insights)
│   ├── scanner_service.dart     # Camera/image scanning pipeline
│   └── storage_service.dart     # Hive local storage layer
├── providers/
│   └── app_state.dart           # Central state management
├── screens/
│   ├── onboarding/
│   │   ├── onboarding_screen.dart   # 3-page intro walkthrough
│   │   └── paywall_screen.dart      # Subscription paywall
│   ├── home/
│   │   ├── home_shell.dart          # Bottom nav shell with scan FAB
│   │   └── dashboard_screen.dart    # Main dashboard with stats & feed
│   ├── scanner/
│   │   ├── scanner_screen.dart      # Camera capture UI
│   │   └── scan_result_screen.dart  # AI analysis results & editing
│   ├── library/
│   │   ├── library_screen.dart      # Bean pantry with search & filters
│   │   └── bean_detail_screen.dart  # Full bean profile & history
│   ├── brew/
│   │   ├── brew_screen.dart         # Brew Lab hub & history
│   │   ├── brew_log_screen.dart     # AI-powered brew logging
│   │   └── brew_detail_screen.dart  # Brew detail with AI feedback
│   ├── journal/
│   │   ├── journal_screen.dart      # Flavor journal timeline
│   │   ├── tasting_note_screen.dart # Create/edit tasting notes
│   │   └── insights_screen.dart     # AI palate insights dashboard
│   ├── discover/
│   │   ├── discover_screen.dart     # Recommendations & subscriptions
│   │   └── roaster_detail_screen.dart # Roaster profile
│   └── settings/
│       ├── settings_screen.dart     # App settings
│       ├── profile_screen.dart      # User profile editing
│       └── equipment_screen.dart    # Equipment setup for AI
└── widgets/
    ├── bean_card.dart               # Reusable bean display card
    ├── brew_card.dart               # Brew log entry card
    ├── flavor_radar_chart.dart      # fl_chart radar visualization
    ├── freshness_bar.dart           # Bean freshness timeline bar
    ├── stat_card.dart               # Statistics display cards
    ├── section_header.dart          # Section header with action
    └── empty_state.dart             # Empty state placeholder
```

## Getting Started

### Prerequisites
- Flutter SDK 3.2+
- Dart 3.2+
- Xcode (for iOS)
- Android Studio (for Android)

### Setup

```bash
# Clone the repository
git clone https://github.com/your-org/bean-ai.git
cd bean-ai

# Install dependencies
flutter pub get

# Run code generation (for freezed/json_serializable if used)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add iOS and Android apps
3. Download and place config files:
   - `ios/Runner/GoogleService-Info.plist`
   - `android/app/google-services.json`
4. Enable Authentication, Firestore, and Storage

### AI Backend
The app connects to a cloud AI backend for:
- Vision-based bean scanning (GPT-4V / Gemini Pro Vision)
- Brew recipe generation
- Palate analysis and recommendations
- Coaching responses

Configure the API endpoint in `lib/services/ai_service.dart`. The app includes mock responses for development.

## Design System

### Color Palette
| Name | Hex | Usage |
|------|-----|-------|
| Espresso | `#2C1810` | Primary dark, text |
| Dark Roast | `#3E2723` | Dark backgrounds |
| Medium Roast | `#5D4037` | Body text |
| Light Roast | `#8D6E63` | Secondary text |
| Crema | `#F5E6D3` | Light accent |
| Milk | `#FAF6F1` | Background |
| Latte | `#EDE0D4` | Card borders |
| Caramel | `#D4A574` | Primary accent |
| Honey | `#E8A849` | Ratings, warnings |
| Cherry | `#B4364A` | Errors, favorites |
| Mint | `#4CAF89` | Success, freshness |
| Blueberry | `#5C6BC0` | Info, resting |

### Typography
- **Display**: Plus Jakarta Sans 800
- **Headlines**: Plus Jakarta Sans 700
- **Body**: Plus Jakarta Sans 400/600
- Consistent sizing scale from 11px labels to 32px display

## Monetization

| Plan | Price | Features |
|------|-------|----------|
| Free | $0 | 5 beans, 20 brews, basic scanning |
| Monthly | $4.99/mo | Unlimited everything, full AI |
| Yearly | $49/yr | Same as monthly, 18% savings |
| Lifetime | $99 | One-time, all features forever |

## License

Proprietary. All rights reserved.
