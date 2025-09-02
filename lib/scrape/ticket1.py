from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
import json
import time

# Setup Chrome options
options = webdriver.ChromeOptions()
#options.add_argument("--headless")  # optional: show browser if needed
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

# Start Chrome WebDriver
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)

# List of URLs to scrape
urls = [
    "https://en.tiket.com/to-do/tiket-encore-melaka-admission-ticket-61761",
    "https://en.tiket.com/to-do/tiket-taming-sari-tower-40333",
    "https://en.tiket.com/to-do/tiket-traditional-nyonya-dessert-cooking-class-in-melaka",
    "https://en.tiket.com/to-do/tiket-ghost-museum-melaka",
    "https://en.tiket.com/to-do/tiket-traditional-costume-experience-in-malacca",
    "https://en.tiket.com/to-do/tiket-ghost-museum-melaka-ticket",
    "https://en.tiket.com/to-do/tiket-skytrex-adventure-melaka",
    "https://en.tiket.com/to-do/tiket-melaka-crocodile-and-recreation-park-ticket",
    "https://en.tiket.com/to-do/tiket-upside-down-house-gallery-melaka-52735",
    "https://en.tiket.com/to-do/tiket-cocomelon-indoor-playground-ticket-in-melaka",
    "https://en.tiket.com/to-do/tiket-encore-melaka-impression-series-ticket",
    "https://en.tiket.com/to-do/tiket-breakout-escape-room-experience-in-the-shore-melaka",
    "https://en.tiket.com/to-do/tiket-melaka-wonderland-58152",
    "https://en.tiket.com/to-do/tiket-malaysia-heritage-studios-ticket-in-malacca",
    "https://en.tiket.com/to-do/tiket-a-famosa-malacca-34129",
    "https://en.tiket.com/to-do/tiket-zoo-melaka-45650",
    "https://en.tiket.com/to-do/tiket-jaya-mata-knife-gallery-admission-in-melaka",
    "https://en.tiket.com/to-do/tiket-wonderpark-melaka-interactive-indoor-playground-41472"
]


all_data = []

for url in urls:
    print(f"\n🔄 Scraping: {url}")
    driver.get(url)
    time.sleep(2)

    # Hide floating app banner
    try:
        driver.execute_script("""
            let banner = document.querySelector('.FloatingBannerDownloadApp_content__oaRpo');
            if (banner) banner.style.display = 'none';
        """)
        print("✅ Floating banner removed.")
    except Exception as e:
        print(f"⚠️ Could not remove banner: {e}")

    # Title
    try:
        title_elem = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, '[data-testid="seo-title"]'))
        )
        title = title_elem.text.strip()
    except:
        title = "N/A"
    print(f"✅ Title: {title}")

    # Click "Open" to reveal opening hours
    try:
        open_btn = WebDriverWait(driver, 5).until(
            EC.element_to_be_clickable((By.XPATH, "//div[contains(text(),'Open')]"))
        )
        open_btn.click()
        print("✅ Clicked 'Open' to reveal opening hours")
        time.sleep(1)
    except Exception as e:
        print(f"❌ Failed to click 'Open': {e}")

    # Opening Hours
    opening_hours = []
    try:
        rows = driver.find_elements(By.CSS_SELECTOR, ".SectionSummary_day_row___uNsN")
        for row in rows:
            day_elem = row.find_element(By.CSS_SELECTOR, ".SectionSummary_day_row_left__uwWtO span")
            time_elem = row.find_element(By.CSS_SELECTOR, "div > span:not([class*='dotted'])")
            opening_hours.append(f"{day_elem.text.strip()}: {time_elem.text.strip()}")
        print(f"✅ Opening Hours: {opening_hours}")
    except Exception as e:
        print(f"❌ Failed to extract opening hours: {e}")

    # Images
    images = []
    try:
        image_tags = driver.find_elements(By.TAG_NAME, "img")
        for img in image_tags:
            src = img.get_attribute("src")
            if src and "https://s-light.tiket.photos" in src:
                images.append(src)
            if len(images) >= 2:
                break
        print(f"✅ Found {len(images)} image(s)")
    except:
        print("❌ Failed to get images")

    # Packages & Tickets per 'Select'
    package_data = []

    try:
        # Get all package names before clicking any buttons
        package_titles = []
        try:
            package_title_elements = driver.find_elements(By.CSS_SELECTOR, "div.PackageCard_wrapper_title__mcrWP h3")
            package_titles = [el.text.strip() for el in package_title_elements]
            print(f"✅ Found {len(package_titles)} package title(s) before clicking 'Select'")
        except Exception as e:
            print(f"❌ Failed to get pre-click package titles: {e}")

        select_buttons = WebDriverWait(driver, 10).until(
            EC.presence_of_all_elements_located((By.XPATH, "//button[contains(text(),'Select')]"))
        )
        print(f"✅ Found {len(select_buttons)} 'Select' buttons")

        original_buttons = select_buttons.copy()

        for i, button in enumerate(original_buttons):
            try:
                driver.execute_script("arguments[0].click();", button)
                time.sleep(2)

                # Use pre-extracted package name
                package_name = package_titles[i] if i < len(package_titles) else f"Package {i+1}"

                # Ticket details
                WebDriverWait(driver, 5).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, "div.TicketQuantity_ticket_name__TY9Ce"))
                )
                ticket_name_elements = driver.find_elements(By.CSS_SELECTOR, "div.TicketQuantity_ticket_name__TY9Ce")
                print(f"Package '{package_name}': Found {len(ticket_name_elements)} ticket(s)")

                tickets = []
                for ticket_div in ticket_name_elements:
                    try:
                        ticket_type = ticket_div.find_element(By.CSS_SELECTOR, "span.Text_weight_bold__YQVH_").text.strip()
                        try:
                            ticket_desc = ticket_div.find_element(By.CSS_SELECTOR, "span.TicketQuantity_ticket_description__vkePs").text.strip()
                        except:
                            ticket_desc = ""

                        price_block = ticket_div.find_element(By.XPATH, "../../../..")
                        ticket_price = price_block.find_element(By.CSS_SELECTOR, "span.Text_variant_alert__HXg9t").text.strip().split("/")[0]

                        tickets.append({
                            "type": ticket_type,
                            "description": ticket_desc,
                            "price": ticket_price
                        })
                    except Exception as e:
                        print(f"❌ Failed to extract individual ticket: {e}")

                if tickets:
                    package_data.append({
                        "package_name": package_name,
                        "tickets": tickets
                    })

                # Close modal
                try:
                    close_btn = WebDriverWait(driver, 3).until(
                        EC.element_to_be_clickable((By.CSS_SELECTOR, "button[aria-label='Close']"))
                    )
                    driver.execute_script("arguments[0].click();", close_btn)
                except:
                    driver.find_element(By.TAG_NAME, 'body').send_keys(Keys.ESCAPE)
                time.sleep(1)

            except Exception as e:
                print(f"❌ Failed to process 'Select' button #{i+1}: {e}")
                continue

    except Exception as e:
        print(f"❌ Could not find or process any 'Select' buttons: {e}")

    # Save data for this URL
    all_data.append({
        "title": title,
        "opening_hours": opening_hours,
        "images": images,
        "packages": package_data,
        "source": url
    })

    time.sleep(2)

# Save to JSON
with open("tiket_all_data.json", "w", encoding="utf-8") as f:
    json.dump(all_data, f, indent=4, ensure_ascii=False)

driver.quit()
print("\n🎉 Scraping selesai dan data disimpan ke 'tiket_all_data.json'")
