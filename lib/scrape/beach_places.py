# === 📦 Required Libraries ===
import requests
import firebase_admin
from firebase_admin import credentials, firestore, storage
import time
from io import BytesIO
from PIL import Image

# === 🔧 FIREBASE SETUP ===
# Load your Firebase service account key
cred = credentials.Certificate(
    r"C:\Users\Acer\Documents\UiTM\SEM 6\Code\fyp25\android\app\service-account-file.json"
)

# Initialize Firebase Admin SDK
firebase_admin.initialize_app(cred, {
    'storageBucket': 'fyp2025-88e54.firebasestorage.app'# ✅ Make sure this matches your actual bucket name
})

# Firestore and Storage clients
db = firestore.client()
bucket = storage.bucket()

# === 🔑 GOOGLE PLACES API KEY ===
API_KEY = ''  # Replace with your actual key

# === 🌍 Melaka Coordinates (for nearby search)
MELAKA_COORDINATE = (2.2000, 102.2500)

# === 🔍 Place types to search
PLACE_TYPES = ['beach']

# === 🧠 Optional mapping of specific types to broader ones
TYPE_MAPPING = {
    'bay': 'beach',
    'public_beach': 'beach',
}

# === Set to avoid duplicate uploads
unique_places = set()

# === 🔗 Generate image URL from Google Place Photo
def get_image_url(photo_reference, maxwidth=400):
    return f"https://maps.googleapis.com/maps/api/place/photo?maxwidth={maxwidth}&photoreference={photo_reference}&key={API_KEY}"

# === ☁️ Upload an image to Firebase Storage
def upload_photo_to_firebase(photo_reference, place_name, index):
    try:
        photo_url = get_image_url(photo_reference)
        response = requests.get(photo_url)
        response.raise_for_status()

        image = Image.open(BytesIO(response.content)).convert('RGB')
        buffer = BytesIO()
        image.save(buffer, format="JPEG")
        buffer.seek(0)

        safe_name = place_name.replace(" ", "_").lower()
        blob_path = f"place_images/{safe_name}/photo_{index}.jpg"
        blob = bucket.blob(blob_path)

        blob.upload_from_file(buffer, content_type='image/jpeg')
        blob.make_public()

        return blob.public_url

    except Exception as e:
        print(f"❌ Error uploading image for {place_name}: {e}")
        return None

# === 📝 Get place details from Google Places API
def get_place_details(place_id):
    url = 'https://maps.googleapis.com/maps/api/place/details/json'
    params = {
        'place_id': place_id,
        'fields': 'review,user_ratings_total,opening_hours,photos',
        'key': API_KEY
    }

    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
        result = response.json().get('result', {})
    except Exception as e:
        print(f"❌ Error getting place details: {e}")
        return {}

    reviews = []
    for review in result.get('reviews', [])[:5]:
        reviews.append({
            'author_name': review.get('author_name'),
            'rating': review.get('rating'),
            'text': review.get('text'),
            'time': review.get('time')
        })

    return {
        'user_ratings_total': result.get('user_ratings_total'),
        'reviews': reviews,
        'opening_hours': result.get('opening_hours', {}),
        'photos': [p.get('photo_reference') for p in result.get('photos', [])[:4]]
    }

# === 🔍 Search places in Melaka
def search_places(location, radius=30000):
    found_places = []

    for keyword in ['beach', 'pantai']:  # Use keywords, not types
        print(f"🔍 Searching for keyword: {keyword}")
        url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        params = {
            'location': f"{location[0]},{location[1]}",
            'radius': radius,
            'keyword': keyword,  # ✅ Use keyword instead of type
            'key': API_KEY
        }

        while True:
            try:
                response = requests.get(url, params=params)
                response.raise_for_status()
                data = response.json()
            except Exception as e:
                print(f"❌ Error during API fetch: {e}")
                break

            for place in data.get('results', []):
                name = place.get('name', '').lower()
                rating = place.get('rating')
                types = place.get('types', [])

                if not name or not rating or name in unique_places:
                    continue

                # ❌ Still skip hotels/resorts
                if 'lodging' in types:
                    continue

                # ✅ Name must contain beach or pantai
                if 'beach' not in name and 'pantai' not in name:
                    continue

                unique_places.add(name)
                place_id = place.get('place_id')
                location_info = place.get('geometry', {}).get('location', {})
                details = get_place_details(place_id)

                found_places.append({
                    'name': place.get('name'),
                    'address': place.get('vicinity'),
                    'rating': rating,
                    'rating_count': details.get('user_ratings_total'),
                    'longitude': location_info.get('lng'),
                    'latitude': location_info.get('lat'),
                    'types': types,
                    'reviews': details.get('reviews'),
                    'opening_hours': details.get('opening_hours'),
                    'photos': details.get('photos'),
                    'searched_type': keyword
                })

            next_token = data.get('next_page_token')
            if next_token:
                print("⏳ Waiting for next page...")
                time.sleep(2)
                params = {'pagetoken': next_token, 'key': API_KEY}
            else:
                break

    return found_places


# === ⬆️ Upload to Firestore and Firebase Storage
def upload_to_firestore(places):
    for place in places:
        print(f"⬆️ Uploading: {place['name']}")
        doc_ref = db.collection('melaka_places').document()
        firebase_photo_urls = []

        for index, photo_ref in enumerate(place.get('photos', [])):
            url = upload_photo_to_firebase(photo_ref, place['name'], index)
            if url:
                firebase_photo_urls.append(url)

        doc_ref.set({
            'name': place['name'],
            'address': place['address'],
            'rating': place['rating'],
            'rating_count': place['rating_count'],
            'longitude': place['longitude'],
            'latitude': place['latitude'],
            'types': place['types'],
            'reviews': place['reviews'],
            'opening_hours': place['opening_hours'],
            'photos': firebase_photo_urls,
            # 🔒 'searched_type' is used internally, not uploaded
        })

        print(f"✅ Uploaded: {place['name']}")

# === 📋 Display places (optional)
def display_places(places):
    for i, place in enumerate(places, 1):
        print(f"{i}. {place['name']} ({place['searched_type']})")

# === 🚀 Entry point
def main():
    print("🚀 Starting place search in Melaka...")
    places = search_places(MELAKA_COORDINATE)
    print(f"\n✅ Total places found: {len(places)}")

    upload_to_firestore(places)
    display_places(places)
    print("\n🎉 Upload complete!")

# === Run main if script is executed
if __name__ == '__main__':
    main()
