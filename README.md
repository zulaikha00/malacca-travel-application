# 🏛️ MyMelaka - Smart Travel Recommendation App

A Flutter-based mobile application that provides personalized recommendations for places to visit in Melaka, Malaysia using **Content-Based Filtering** and **Machine Learning**.

## 📱 Features

### ✨ Core Functionality
- **Personalized Recommendations**: AI-powered place suggestions based on user preferences and likes
- **Content-Based Filtering**: Uses TF-IDF algorithm for intelligent matching
- **Machine Learning Tags**: Automatic tag generation using zero-shot classification
- **User Authentication**: Secure login/registration with Firebase
- **Interactive Maps**: Google Maps integration with location services
- **Dark/Light Theme**: Dynamic theme switching

### 🎯 Recommendation System
- **User Preference Learning**: Tracks user interests and liked places
- **Smart Tag Matching**: ML-generated tags for accurate place categorization
- **Similarity Scoring**: Cosine similarity algorithm for precise recommendations
- **Real-time Updates**: Dynamic recommendations based on user behavior

### 🗺️ Place Management
- **Comprehensive Database**: Curated collection of Melaka tourist destinations
- **Rich Information**: Photos, ratings, reviews, opening hours, and location data
- **Category Filtering**: Filter places by type, tags, and preferences
- **Search Functionality**: Find places by name, location, or features

## 🏗️ Architecture

### Frontend (Flutter)
- **Cross-platform**: iOS, Android, Web support
- **State Management**: Provider pattern for app-wide state
- **Responsive Design**: Adaptive UI for different screen sizes
- **Modern UI**: Material Design 3 with custom theming

### Backend (Firebase)
- **Authentication**: Firebase Auth for user management
- **Database**: Cloud Firestore for data storage
- **Storage**: Firebase Storage for images and media
- **Functions**: Cloud Functions for server-side logic

### Machine Learning
- **Zero-Shot Classification**: HuggingFace Transformers for tag prediction
- **Python Scripts**: Automated data processing and tag generation
- **TF-IDF Algorithm**: Term Frequency-Inverse Document Frequency for recommendations

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: Version 3.7.2 or higher
- **Dart SDK**: Compatible with Flutter version
- **Python**: 3.8+ for ML scripts
- **Firebase Account**: For backend services
- **Google Cloud Platform**: For Maps API and Places API

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/fyp25.git
   cd fyp25
   ```

2. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Python Dependencies**
   ```bash
   cd lib/scrape
   pip install -r requirements.txt
   ```

4. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication, Firestore, Storage, and Functions
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the respective platform directories

5. **Google Maps API Setup**
   - Get Google Maps API key from Google Cloud Console
   - Enable Places API, Maps SDK, and Geocoding API
   - Update the API key in `android/app/src/main/AndroidManifest.xml`

6. **Environment Configuration**
   - Copy `.env.example` to `.env`
   - Fill in your Firebase and Google API credentials

### Running the Application

#### Flutter App
```bash
# Run on connected device/emulator
flutter run

# Build for production
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

#### ML Scripts (Optional)
```bash
cd lib/scrape

# Generate ML tags for places
python try.py

# Scrape new places
python melaka_places.py
python beach_places.py
python mosque.py
```

## 📁 Project Structure

```
fyp25/
├── lib/                          # Main Flutter application code
│   ├── main.dart                # App entry point
│   ├── page/                    # Main app pages
│   │   ├── homepage.dart        # Home screen with recommendations
│   │   ├── recommendation_service.dart  # Core recommendation logic
│   │   └── recommendation_places.dart   # Recommendation display
│   ├── places/                  # Place-related screens
│   ├── profile/                 # User profile management
│   ├── admin/                   # Admin panel for place management
│   ├── search/                  # Search functionality
│   ├── navigation/              # Bottom navigation
│   ├── theme/                   # App theming
│   └── widgets/                 # Reusable UI components
├── lib/scrape/                  # Python ML scripts
│   ├── try.py                   # Main ML tag generation script
│   ├── melaka_places.py         # Scrape general places
│   ├── beach_places.py          # Scrape beach locations
│   ├── mosque.py                # Scrape religious places
│   └── upload_to_firestore.py   # Data upload utilities
├── assets/                      # Images and static resources
├── android/                     # Android-specific configuration
├── ios/                         # iOS-specific configuration
└── test/                        # Unit and widget tests
```

## 🔧 Configuration

### Firebase Configuration
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // ... rest of initialization
}
```

### Google Maps Configuration
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>
```

### ML Model Configuration
```python
# lib/scrape/try.py
zero_shot_classifier = pipeline(
    "zero-shot-classification", 
    model="facebook/bart-large-mnli"
)
```

## 📊 Content-Based Filtering Implementation

### How It Works
1. **User Profile Creation**: Builds user preference vector from likes and preferences
2. **TF-IDF Calculation**: Computes term frequency and inverse document frequency
3. **Vector Similarity**: Uses cosine similarity to match user profile with places
4. **Recommendation Ranking**: Sorts places by similarity score and relevance

### Key Algorithms
- **TF-IDF**: Term Frequency-Inverse Document Frequency for tag weighting
- **Cosine Similarity**: Measures angle between user and place vectors
- **Zero-Shot Classification**: ML-based tag prediction for places

## 🧪 Testing

### Flutter Tests
```bash
# Run unit tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

### ML Accuracy Testing
```bash
cd lib/testing
python cbf_accuracy_tester.py
```

## 📱 Screenshots

[Add screenshots of your app here]

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Your Name** - Final Year Project (FYP25)
- **University**: UiTM
- **Course**: [Your Course Name]
- **Supervisor**: [Supervisor Name]

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Firebase** for backend services
- **HuggingFace** for ML models
- **Google** for Maps and Places APIs
- **Open Source Community** for various packages

## 📞 Support

If you encounter any issues or have questions:

1. **Check the Issues** section on GitHub
2. **Create a new issue** with detailed description
3. **Contact the author** at [your.email@example.com]

## 🔮 Future Enhancements

- [ ] Collaborative filtering implementation
- [ ] Real-time notifications
- [ ] Offline mode support
- [ ] Multi-language support
- [ ] Advanced analytics dashboard
- [ ] Social features (reviews, ratings)

---

**Made with ❤️ for Melaka Tourism**
