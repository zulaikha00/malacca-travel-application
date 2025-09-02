import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup
import firebase_admin
from firebase_admin import credentials, firestore
import json

# ---------------- FIREBASE SETUP ----------------
cred = credentials.Certificate(
    r"C:\Users\Acer\Documents\UiTM\SEM 6\Code\fyp25\android\app\service-account-file.json"
)
firebase_admin.initialize_app(cred)
db = firestore.client()

# ---------------- SELENIUM SETUP ----------------
options = Options()
options.headless = True  # Run Chrome in headless mode
driver = webdriver.Chrome(options=options)

# ---------------- URL LIST ----------------
urls = [
    "https://www.ticket2u.com.my/mhs/book",
    "https://www.ticket2u.com.my/event/31588/wonderpark-melaka-ticket",
    "https://www.ticket2u.com.my/event/27092/menara-taming-sari,-melaka-ticket",
    "https://www.ticket2u.com.my/event/19446/melaka-butterfly-reptile-sanctuary-(taman-rama-rama-reptilia-melaka)-ticket",
    "https://www.ticket2u.com.my/event/35554/melaka-wonderland-water-theme-park-ticket",
    "https://www.ticket2u.com.my/event/34795/iman-rabbit-farm,-melaka",
    "https://www.ticket2u.com.my/event/26419/taman-buaya-rekreasi-melaka-(melaka-crocodile-recreational-park)-ticket",
    "https://www.ticket2u.com.my/event/22026/upside-down-house-melaka-ticket",
    "https://www.ticket2u.com.my/event/18457/adopt-a-butterfly-melaka-butterfly-reptile-sanctuary"
]

def is_visible_style(style_str):
    """
    Returns True if element is visible (no display:none),
    considering spacing and case insensitivity.
    """
    if not style_str:
        return True
    style_clean = style_str.replace(' ', '').lower()
    return 'display:none' not in style_clean

def extract_price(item):
    """
    Extract the first visible MYR price from the ticket item,
    ignoring any prices that contain 'USD'.
    """
    # Check for span with visible MYR price
    price_span = item.find('span', class_='font--bold color--red')
    if price_span:
        style = price_span.get('style', '')
        if is_visible_style(style):
            text = price_span.get_text(strip=True)
            if text and 'MYR' in text and 'USD' not in text:
                return text

    # Fallback: check subtitle div for visible MYR prices
    subtitle_div = item.find('div', class_='card__item__subtitle')
    if subtitle_div:
        for div in subtitle_div.find_all(['div', 'span']):
            style = div.get('style', '')
            if is_visible_style(style):
                text = div.get_text(strip=True)
                if 'MYR' in text and 'USD' not in text:
                    return text
    return ''


def extract_description(soup):
    """
    Extracts the main event description from the page.
    """
    desc_div = soup.find('div', class_='card__desc')
    if desc_div:
        inner_div = desc_div.find('div', style=lambda s: s and 'white-space:pre-line' in s)
        if inner_div:
            return inner_div.get_text(strip=True)
    return ''

def scrape_event(url):
    driver.get(url)

    try:
        WebDriverWait(driver, 15).until(
            EC.presence_of_element_located((By.CLASS_NAME, 'oTicketInfo'))
        )
    except Exception as e:
        print(f"Timeout or error loading tickets on {url}: {e}")

    time.sleep(2)  # extra wait for page to fully load

    soup = BeautifulSoup(driver.page_source, 'html.parser')

    # Event Name
    event_name_tag = soup.find('h1')
    event_name = event_name_tag.get_text(strip=True) if event_name_tag else 'Event name not found'

    # Operation Hours
    operation_hours_div = soup.find('div', class_='padding-top-s padding-bottom-s')
    operation_hours = operation_hours_div.get_text(strip=True) if operation_hours_div else 'Operation hours not found'

    # Description
    description = extract_description(soup)

    # Ticket Pricing
    tickets = []
    ticket_container = soup.find('div', class_='oTicketInfo')
    if ticket_container:
        ticket_cards = ticket_container.find_all('div', class_='card--ticket')
        for card in ticket_cards:
            # Category Name
            category_div = card.find('div', class_='card__title')
            if category_div:
                # Remove all hidden divs inside category title before extracting text
                for hidden_div in category_div.find_all('div', style=lambda s: s and not is_visible_style(s)):
                    hidden_div.decompose()
                category_name = category_div.get_text(strip=True)
            else:
                category_name = 'Unknown Category'

            # Category Description
            category_desc_div = card.find('div', class_='card__desc')
            if category_desc_div:
                inner_div = category_desc_div.find('div', style=lambda s: s and 'white-space:pre-line' in s)
                category_description = inner_div.get_text(strip=True) if inner_div else '-'
            else:
                category_description = '-'

            subcategories = []
            ticket_items = card.find_all('div', class_='card__item')
            if not ticket_items:
                ticket_items = card.find_all('div', class_='card__item row')

            for item in ticket_items:
                subcat_div = item.find('div', class_='card__item__title')
                if not subcat_div:
                    continue
                # Remove hidden divs inside subcategory title
                for hidden_div in subcat_div.find_all('div', style=lambda s: s and not is_visible_style(s)):
                    hidden_div.decompose()
                subcategory_name = subcat_div.get_text(strip=True)

                price = extract_price(item)

                subcategories.append({
                    'subcategory': subcategory_name,
                    'price': price
                })

            tickets.append({
                'category': category_name,
                'description': category_description,
                'subcategories': subcategories
            })

    # Build ticket pricing dictionary
    ticket_pricing = {}
    for ticket_category in tickets:
        cat_name = ticket_category['category']
        ticket_pricing[cat_name] = {
            'description': ticket_category['description'],
            'subcategories': {}
        }
        for subcat in ticket_category['subcategories']:
            ticket_pricing[cat_name]['subcategories'][subcat['subcategory']] = subcat['price']

    # Images extraction
    hero_div = soup.find('div', class_='details__hero')
    image_url_1 = ''
    image_url_2 = ''
    if hero_div:
        bg_div = hero_div.find('div', class_='details__hero__bg')
        if bg_div and bg_div.has_attr('style'):
            style = bg_div['style']
            if 'background-image' in style:
                start = style.find("url('") + 5
                end = style.find("')", start)
                image_url_1 = style[start:end]

        img_tag = hero_div.find('img')
        if img_tag and img_tag.has_attr('src'):
            image_url_2 = img_tag['src']

    # Compose final event dictionary
    event_data = {
        "name": event_name,
        "operation_hours": operation_hours,
        "ticket_pricing": ticket_pricing,
        "image_1": image_url_1,
        "image_2": image_url_2
    }

    return event_data

def upload_to_firestore(event):
    doc_ref = db.collection('tickets').document()
    doc_ref.set(event)
    print(f"Uploaded event: {event['name']}")

# Main scraping loop
for url in urls:
    print(f"Scraping {url}")
    event_data = scrape_event(url)
    print(json.dumps(event_data, indent=2, ensure_ascii=False))
    upload_to_firestore(event_data)

driver.quit()
