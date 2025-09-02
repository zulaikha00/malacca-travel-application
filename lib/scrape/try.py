import firebase_admin
from firebase_admin import credentials, firestore
import requests
from transformers import pipeline

# === Firebase Setup ===
cred = credentials.Certificate(
    r"C:\Users\Acer\Documents\UiTM\SEM 6\Code\fyp25\android\app\service-account-file.json"
)
firebase_admin.initialize_app(cred)
db = firestore.client()

# === API Key ===
API_KEY = ''

# === ML Model ===
zero_shot_classifier = pipeline("zero-shot-classification", model="facebook/bart-large-mnli")

PREDICTED_TAGS = [
    "Family Friendly", "Adventure", "Extreme", "Relaxing",
    "Nature", "Beach", "Cultural", "Historical", "Heritage", "Religious",
    "Photogenic", "Instagrammable",
    "Shopping", "Budget Friendly",
    "Foodie", "Local Cuisine",
    "Educational", "Wheelchair Accessible", "Parking Available"
]

# === 🔍 Get place_id by name using Text Search API ===
def get_place_id_from_name(name):
    url = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    params = {
        "query": name + " Melaka",
        "key": API_KEY
    }
    try:
        res = requests.get(url, params=params)
        res.raise_for_status()
        results = res.json().get("results", [])
        if results:
            return results[0].get("place_id")
    except Exception as e:
        print(f"❌ Error finding place_id for {name}: {e}")
    return None

# === 📋 Get reviews using place_id ===
def get_reviews_from_places_api(place_id):
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
        "place_id": place_id,
        "fields": "review",
        "key": API_KEY
    }
    try:
        res = requests.get(url, params=params)
        res.raise_for_status()
        reviews = res.json().get("result", {}).get("reviews", [])
        return [r.get("text", "") for r in reviews if r.get("text")]
    except Exception as e:
        print(f"❌ Error getting reviews for place_id {place_id}: {e}")
        return []

# === 📝 Build ML Description ===
def build_description(name, types, website, reviews):
    description = f"{name} is a place in Melaka. "
    if types:
        description += f"It is known for {', '.join(types)}. "
    if website:
        description += f"More info at {website}. "
    review_text = " ".join(reviews)
    if not review_text.strip():
        review_text = "No user reviews available at the moment."
    description += f"Visitors say: {review_text}"
    return description

# === 🧠 Smart Tag Selector ===
def select_tags_by_scores(name, predicted_tags_with_scores, types):
    name_lower = name.lower()
    types_lower = [t.lower() for t in types]
    selected_tags = []

    for tag, score in predicted_tags_with_scores:
        # ⛱️ Resorts & Hotels
        if any(k in name_lower for k in ["resort", "hotel"]) or "lodging" in types_lower:
            if tag in ["Relaxing", "Family Friendly", "Photogenic", "Parking Available"]:
                selected_tags.append(tag)

        # 🎢 Parks
        elif ("theme park" in name_lower or "water park" in name_lower or "amusement" in types_lower) and tag in ["Family Friendly", "Adventure", "Photogenic"]:
            selected_tags.append(tag)

        # 🏛️ Museums & Galleries
        elif "museum" in name_lower or "museum" in types_lower:
            if tag in ["Historical", "Educational", "Cultural"]:
                selected_tags.append(tag)
        elif "gallery" in name_lower and tag in ["Photogenic", "Instagrammable", "Cultural"]:
            selected_tags.append(tag)

        # 🏖️ Beaches
        elif any(k in name_lower for k in ["beach", "bay"]) or "natural_feature" in types_lower:
            if tag in ["Beach", "Relaxing", "Nature"]:
                selected_tags.append(tag)

        # ☕ Cafes
        elif any(k in name_lower for k in ["cafe", "coffee"]) or "cafe" in types_lower:
            if tag in ["Foodie", "Relaxing"]:
                selected_tags.append(tag)

        # 🛍️ Malls
        elif any(k in name_lower for k in ["mall", "market"]) or "shopping_mall" in types_lower:
            if tag in ["Shopping", "Budget Friendly", "Foodie"]:
                selected_tags.append(tag)

        # 🍽️ Restaurants
        elif "restaurant" in name_lower or "restaurant" in types_lower:
            if tag in ["Foodie", "Local Cuisine"]:
                selected_tags.append(tag)

        # 🏕️ Camping
        elif "camp" in name_lower or "campground" in types_lower:
            if tag in ["Nature", "Adventure", "Relaxing"]:
                selected_tags.append(tag)

        # 🕌 Religious Places
        elif any(k in name_lower for k in ["masjid", "mosque", "gereja", "church", "temple", "tokong", "kuil"]) or "place_of_worship" in types_lower:
            if tag in ["Cultural", "Historical", "Heritage", "Religious", "Photogenic"]:
                selected_tags.append(tag)

        # 🏰 A Famosa Special Case
        elif "a famosa" in name_lower:
            if "water" in name_lower and tag in ["Family Friendly", "Adventure"]:
                selected_tags.append(tag)
            elif tag in ["Historical", "Heritage", "Photogenic"]:
                selected_tags.append(tag)

        # ✅ Score-based fallback
        elif score >= 0.09:
            selected_tags.append(tag)

    return list(set(selected_tags))

# === 🔄 Update Firestore ===
# === 🔄 Update Firestore ===
def update_existing_places_by_name():
    docs = db.collection("melaka_places").stream()

    for doc in docs:
        data = doc.to_dict()
        name = data.get("name")
        types = data.get("types", [])
        website = data.get("website")
        existing_tags = data.get("tags_suggested_by_ml")

        if existing_tags:
            print(f"⏭️ Skipping {name}: tags already exist")
            continue

        print(f"\n🔍 Processing: {name}")
        place_id = data.get("place_id")

        if not place_id:
            place_id = get_place_id_from_name(name)
            if not place_id:
                print(f"⚠️ Skipped {name}: place_id not found")
                continue
            db.collection("melaka_places").document(doc.id).update({
                "place_id": place_id
            })
            print(f"📌 Stored place_id for {name}")

        reviews = get_reviews_from_places_api(place_id)
        description = build_description(name, types, website, reviews)

        prediction = zero_shot_classifier(description, candidate_labels=PREDICTED_TAGS)
        predicted_tags = list(zip(prediction["labels"], prediction["scores"]))
        selected_tags = select_tags_by_scores(name, predicted_tags, types)

        db.collection("melaka_places").document(doc.id).update({
            "tags_suggested_by_ml": selected_tags
        })

        print(f"✅ Updated {name} with tags: {selected_tags}")
# === 🚀 Run Script ===
if __name__ == "__main__":
    update_existing_places_by_name()
