import requests
import firebase_admin
from firebase_admin import credentials, firestore, storage
import time
from io import BytesIO
from PIL import Image

# === 🔧 Firebase Setup ===
cred = credentials.Certificate(
    r"C:\Users\Acer\Documents\UiTM\SEM 6\Code\fyp25\android\app\service-account-file.json"
)

firebase_admin.initialize_app(cred, {
    'storageBucket': 'fyp2025-88e54.firebasestorage.app'
})

db = firestore.client()
bucket = storage.bucket()

# === 🔑 Google Places API Key
API_KEY = ''  # Replace with your actual key

# === 🌍 Melaka Coordinates
MELAKA_COORD = (2.2000, 102.2500)

# === Set to avoid duplicates
unique_places = set()

# === 💡 Predict Tags using simple rule-based logic
def predict_tags(name, types):
    name_lower = name.lower()
    types_lower = [t.lower() for t in types]
    selected_tags = []

    tag_keywords = {
        "Religious": ["masjid", "mosque", "place_of_worship"],
        "Heritage": ["heritage", "sejarah"],
        "Photogenic": ["view", "photo", "selat", "landmark"]
    }

    for tag, keywords in tag_keywords.items():
        if any(k in name_lower for k in keywords) or any(k in types_lower for k in keywords):
            selected_tags.append(tag)

    return list(set(selected_tags))

# === 🔗 Get Google Place Photo URL
def get_image_url(photo_reference, maxwidth=400):
    return f"https://maps.googleapis.com/maps/api/place/photo?maxwidth={maxwidth}&photoreference={photo_reference}&key={API_KEY}"

# === ☁️ Upload photo to Firebase Storage
def upload_photo(photo_reference, place_name, index):
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
        print(f"❌ Failed to upload image: {e}")
        return None

# === 📋 Get extra details (reviews, photos)
def get_place_details(place_id):
    url = 'https://maps.googleapis.com/maps/api/place/details/json'
    params = {
        'place_id': place_id,
        'fields': 'review,user_ratings_total,opening_hours,photos',
        'key': API_KEY
    }

    try:
        res = requests.get(url, params=params)
        res.raise_for_status()
        result = res.json().get('result', {})
    except Exception as e:
        print(f"❌ Details fetch failed: {e}")
        return {}

    reviews = [{
        'author_name': r.get('author_name'),
        'rating': r.get('rating'),
        'text': r.get('text'),
        'time': r.get('time')
    } for r in result.get('reviews', [])[:5]]

    return {
        'user_ratings_total': result.get('user_ratings_total'),
        'reviews': reviews,
        'opening_hours': result.get('opening_hours', {}),
        'photos': [p.get('photo_reference') for p in result.get('photos', [])[:4]]
    }

# === 🔍 Search for mosques in Melaka
def search_mosques(location, radius=30000):
    print("🔍 Searching for masjid/mosque...")
    found_places = []

    for keyword in ['masjid', 'mosque']:
        url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        params = {
            'location': f"{location[0]},{location[1]}",
            'radius': radius,
            'keyword': keyword,
            'key': API_KEY
        }

        while True:
            try:
                response = requests.get(url, params=params)
                response.raise_for_status()
                data = response.json()
            except Exception as e:
                print(f"❌ Search failed: {e}")
                break

            for place in data.get('results', []):
                name = place.get('name', '').lower()
                rating = place.get('rating')
                types = place.get('types', [])
                place_id = place.get('place_id')
                location_info = place.get('geometry', {}).get('location', {})

                if not name or not rating or name in unique_places:
                    continue

                # ❌ Skip if already in Firestore
                existing_docs = db.collection('melaka_places').where('name', '==', place.get('name')).stream()
                if any(True for _ in existing_docs):
                    print(f"⏩ Skipped (already exists): {place.get('name')}")
                    continue

                unique_places.add(name)

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
                })

            next_token = data.get('next_page_token')
            if next_token:
                time.sleep(2)
                params = {'pagetoken': next_token, 'key': API_KEY}
            else:
                break

    return found_places

# === ⬆️ Upload all to Firestore
def upload_to_firestore(places):
    for place in places:
        print(f"⬆️ Uploading: {place['name']}")
        doc_ref = db.collection('melaka_places').document()

        # Upload photos
        firebase_urls = []
        for i, photo_ref in enumerate(place.get('photos', [])):
            url = upload_photo(photo_ref, place['name'], i)
            if url:
                firebase_urls.append(url)

        tags = predict_tags(place['name'], place['types'])

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
            'photos': firebase_urls,
            'tags_suggested_by_ml': tags
        })

        print(f"✅ Uploaded: {place['name']}")

# === 🚀 Main
def main():
    places = search_mosques(MELAKA_COORD)
    print(f"✅ Found {len(places)} new mosques")
    upload_to_firestore(places)
    print("🎉 All done!")

if __name__ == '__main__':
    main()
