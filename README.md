Malacca Travel Application with Personalized Recommendations using Content-Based Filtering


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

Installation

1. **Clone the Repository**
   ```bash
  git clone https://github.com/zulaikha00/malacca-travel-application.git
   cd malacca-travel-application   ```

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


