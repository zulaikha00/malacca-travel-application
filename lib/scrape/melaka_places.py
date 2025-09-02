# === Required Libraries ===
import requests
import firebase_admin
from firebase_admin import credentials, firestore, storage
import time
from io import BytesIO
from PIL import Image

# === 🔧 FIREBASE SETUP ===
# Load your Firebase project's service account key
cred = credentials.Certificate(
    r"C:\Users\Acer\Documents\UiTM\SEM 6\Code\fyp25\android\app\service-account-file.json"
)

# Initialize Firebase Admin SDK with Firestore and Cloud Storage
firebase_admin.initialize_app(cred, {
    'storageBucket': 'fyp2025-88e54.firebasestorage.app'  # ✅ Correct bucket name
})

db = firestore.client()
bucket = storage.bucket()

# === 🔑 GOOGLE PLACES API KEY ===
API_KEY = ''  # Replace with your actual key

# === 🌍 CENTER OF MELAKA FOR SEARCHING ===
MELAKA_COORDINATE = (2.2000, 102.2500)

# === FILTERING: Only Melaka addresses ===
MELAKA_KEYWORDS = ['melaka']


# === 📍 LIST OF PLACE TYPES TO SEARCH FOR TOURISM ===
PLACE_TYPES = [
    'tourist_attraction', 'museum', 'art_gallery', 'park',
    'beach', 'campground', 'shopping_mall', 'cafe',
    'bay', 'outlet_mall', 'night_market', 'restaurant'
]

# === 🧠 Mapping narrower types to broader categories (for classification) ===
TYPE_MAPPING = {
    'bay': 'beach',
    'public_beach': 'beach',
    'campground': 'camping_ground',
    'camping_site': 'camping_ground',
    'shopping_mall': 'shopping_malls',
    'gift_shop': 'shopping_malls',
    'coffee_shop': 'cafe',
}

# === Used to avoid uploading the same place twice ===
unique_places = set()


# === 🔗 Get Google Place Photo URL from its photo_reference ===
def get_image_url(photo_reference, maxwidth=400):
    return f"https://maps.googleapis.com/maps/api/place/photo?maxwidth={maxwidth}&photoreference={photo_reference}&key={API_KEY}"


# === ☁️ Upload image to Firebase Storage ===
def upload_photo_to_firebase(photo_reference, place_name, index):
    try:
        photo_url = get_image_url(photo_reference)
        response = requests.get(photo_url)
        response.raise_for_status()

        # Convert to RGB and buffer as JPEG
        image = Image.open(BytesIO(response.content)).convert('RGB')
        buffer = BytesIO()
        image.save(buffer, format="JPEG")
        buffer.seek(0)

        # Create safe storage path
        safe_name = place_name.replace(" ", "_").lower()
        blob_path = f"place_images/{safe_name}/photo_{index}.jpg"
        blob = bucket.blob(blob_path)

        # Upload and make image public
        blob.upload_from_file(buffer, content_type='image/jpeg')
        blob.make_public()
        return blob.public_url

    except Exception as e:
        print(f"❌ Error uploading image for {place_name}: {e}")
        return None


# === 🏨 Get more details like reviews, hours, photos ===
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

    # Extract up to 5 reviews
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


# === 🔍 Search nearby places based on types defined above ===
def search_places(location, radius=30000):
    found_places = []

    for place_type in PLACE_TYPES:
        print(f"🔍 Searching for type: {place_type}")
        url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        params = {
            'location': f"{location[0]},{location[1]}",
            'radius': radius,
            'type': place_type,
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
                name = place.get('name')
                rating = place.get('rating')

                if not name or not rating or name in unique_places:
                    continue  # Skip if no data or duplicate

                unique_places.add(name)
                place_id = place.get('place_id')
                location_info = place.get('geometry', {}).get('location', {})
                details = get_place_details(place_id)

                # Normalize place type
                broad_type = TYPE_MAPPING.get(place_type, place_type)

                # Save place info
                found_places.append({
                    'name': name,
                    'address': place.get('vicinity'),
                    'rating': rating,
                    'rating_count': details.get('user_ratings_total'),
                    'longitude': location_info.get('lng'),
                    'latitude': location_info.get('lat'),
                    'types': place.get('types'),
                    'reviews': details.get('reviews'),
                    'opening_hours': details.get('opening_hours'),
                    'photos': details.get('photos'),
                    'searched_type': broad_type
                })

            # 🔄 If next page exists, wait and fetch
            next_token = data.get('next_page_token')
            if next_token:
                print("⏳ Waiting for next page...")
                time.sleep(2)
                params = {'pagetoken': next_token, 'key': API_KEY}
            else:
                break

    return found_places


# === ⬆️ Upload each place's data and images to Firestore and Firebase Storage ===
def upload_to_firestore(places):
    for place in places:
        print(f"⬆️ Uploading: {place['name']}")
        doc_ref = db.collection('melaka_places').document()
        firebase_photo_urls = []

        for index, photo_ref in enumerate(place.get('photos', [])):
            url = upload_photo_to_firebase(photo_ref, place['name'], index)
            if url:
                firebase_photo_urls.append(url)

        # Upload document to Firestore
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
        })

        print(f"✅ Uploaded: {place['name']}")


# === 📋 Print list of places in terminal (optional) ===
def display_places(places):
    for i, place in enumerate(places, 1):
        print(f"{i}. {place['name']} ({place['searched_type']})")


# === 🚀 ENTRY POINT ===
def main():
    print("🚀 Starting place search in Melaka...")
    places = search_places(MELAKA_COORDINATE)
    print(f"\n✅ Total places found: {len(places)}")

    upload_to_firestore(places)
    display_places(places)
    print("\n🎉 Upload complete!")


# === Execute when run directly ===
if __name__ == '__main__':
    main()
