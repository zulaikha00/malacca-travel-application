import firebase_admin
from firebase_admin import credentials, firestore

# 🔑 Replace with your Firebase service account key
cred = credentials.Certificate(
    r"C:\Users\Acer\Documents\UiTM\SEM 6\Code\fyp25\android\app\service-account-file.json"
)
firebase_admin.initialize_app(cred)

db = firestore.client()

def clean_duplicate_places():
    print("🔍 Fetching documents from 'melaka_places'...")
    docs = db.collection("melaka_places").stream()

    name_map = {}

    # 🔄 Group documents by name
    for doc in docs:
        data = doc.to_dict()
        name = data.get('name', '').strip()
        if not name:
            continue
        if name not in name_map:
            name_map[name] = []
        name_map[name].append((doc.id, data))

    print("🧹 Processing duplicates...")
    for name, entries in name_map.items():
        if len(entries) <= 1:
            continue  # not a duplicate

        # Just delete ONE of them (keep the first one)
        to_delete = entries[1:]  # keep the first

        for doc_id, _ in to_delete:
            db.collection("melaka_places").document(doc_id).delete()
            print(f"❌ Deleted duplicate for '{name}': {doc_id}")

    print("✅ Cleanup done.")

if __name__ == "__main__":
    clean_duplicate_places()
