import firebase_admin
from firebase_admin import credentials, firestore, storage
import requests
import json
import uuid

# === Step 1: Initialize Firebase ===
cred = credentials.Certificate(
    r"C:\Users\Acer\Documents\UiTM\SEM 6\Code\fyp25\android\app\service-account-file.json"
)
firebase_admin.initialize_app(cred, {
     'storageBucket': 'fyp2025-88e54.firebasestorage.app'  # Replace with your actual bucket name
})
db = firestore.client()
bucket = storage.bucket()

# === Step 2: Load your local JSON data ===
with open("tiket_all_data.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# === Step 3: Upload image to Firebase Storage and return URL ===
def upload_image_to_storage(image_url):
    try:
        response = requests.get(image_url)
        response.raise_for_status()
        image_data = response.content

        # Generate unique filename
        file_name = f"ticket/{uuid.uuid4()}.jpg"

        # Create blob and upload
        blob = bucket.blob(file_name)
        blob.upload_from_string(image_data, content_type='image/jpeg')

        # Make image public (optional)
        blob.make_public()

        return blob.public_url
    except Exception as e:
        print(f"⚠️ Failed to upload image: {e}")
        return None

# === Step 4: Loop and upload ===
for i, item in enumerate(data):
    print(f"\n📦 Processing item {i+1}: {item.get('title')}")
    item_copy = dict(item)

    uploaded_image_urls = []
    for img_url in item.get("images", []):
        new_url = upload_image_to_storage(img_url)
        if new_url:
            uploaded_image_urls.append(new_url)

    item_copy["images"] = uploaded_image_urls
    db.collection("list_ticket").add(item_copy)
    print("✅ Uploaded to Firestore with Firebase Storage image URLs.")

print("\n🎉 All data uploaded successfully.")
