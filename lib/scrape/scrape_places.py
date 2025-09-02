import requests
import firebase_admin
from firebase_admin import credentials, firestore
import time
import base64
from io import BytesIO
from PIL import Image

# === FIREBASE SETUP ===
cred = credentials.Certificate(r"C:\Users\Acer\Documents\UiTM\SEM 6\Code\fyp25\android\app\service-account-file.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# === GOOGLE API KEY ===
API_KEY = ''  # Replace with your actual API key

# === MELAKA CENTER COORDINATES ===
MELAKA_COORDINATE = (2.2000, 102.2500)  # Centralized search point

# === FILTERING: Only Melaka addresses ===
MELAKA_KEYWORDS = ['melaka']

# === MAIN TOURIST PLACE TYPES ===
PLACE_TYPES = [
    'tourist_attraction',
    'museum',
    'art_gallery',
    'park'
]

# === To avoid duplicate names globally ===
unique_places = set()

# === Get more details of each place ===
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
        print(f"Error fetching place details: {e}")
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

    # Return detailed information
    return {
        'user_ratings_total': result.get('user_ratings_total'),
        'reviews': reviews,
        'opening_hours': result.get('opening_hours', {}),
        'photos': [p.get('photo_reference') for p in result.get('photos', [])[:4]]
    }

# === Convert photo URL to base64 ===
def convert_image_to_base64(image_url):
    try:
        response = requests.get(image_url)
        response.raise_for_status()
        image = Image.open(BytesIO(response.content))
        buffer = BytesIO()
        image.save(buffer, format="JPEG")
        return base64.b64encode(buffer.getvalue()).decode('utf-8')
    except Exception as e:
        print(f"Error converting image: {e}")
        return None

# === Get image URL from photo reference ===
def get_image_url(photo_reference, maxwidth=400):
    return f"https://maps.googleapis.com/maps/api/place/photo?maxwidth={maxwidth}&photoreference={photo_reference}&key={API_KEY}"

# === Search nearby attractions ===
def search_places(location, radius=30000):
    found_places = []

    for place_type in PLACE_TYPES:
        print(f"🔍 Searching: {place_type}")
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
                print(f"Error fetching places: {e}")
                break

            for place in data.get('results', []):
                name = place.get('name')
                rating = place.get('rating')

                # Skip if no name or rating or already added
                if not name or not rating or name in unique_places:
                    continue

                unique_places.add(name)

                place_id = place.get('place_id')
                location_info = place.get('geometry', {}).get('location', {})
                details = get_place_details(place_id)

                # Save place info with vicinity (address)
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
                    'searched_type': place_type
                })

            # Check for next page token to fetch more results
            next_page_token = data.get('next_page_token')
            if next_page_token:
                time.sleep(2)  # API requires slight delay before next page token is valid
                params = {
                    'pagetoken': next_page_token,
                    'key': API_KEY
                }
                url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            else:
                break

    return found_places

# === Upload data to Firestore ===
# === Upload data to Firestore ===
def upload_to_firestore(places):
    for place in places:
        doc_ref = db.collection('melaka').document()
        photo_urls = []

        for photo_ref in place['photos']:
            img_url = get_image_url(photo_ref)  # Direct photo URL using photo_reference
            photo_urls.append(img_url)

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
            'photos': photo_urls,  # Save URLs instead of base64
        })


# === Display places in terminal ===
def display_places(places):
    for i, place in enumerate(places, 1):
        print(f"\nPlace #{i}:")
        print(f"Name: {place['name']}")

# === MAIN FUNCTION ===
def main():
    print("\n🚀 Starting search for Melaka tourist attractions...")
    places = search_places(MELAKA_COORDINATE)
    print(f"\n✅ Total places found: {len(places)}")

    # Upload to Firestore
    upload_to_firestore(places)

    # Display places in terminal
    display_places(places)
    print("\n✅ Display complete!")

if __name__ == '__main__':
    main()
