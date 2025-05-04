from machine import Pin, SPI
from mfrc522 import MFRC522
import neopixel
import network
import urequests
import ujson
import time

np = neopixel.NeoPixel(Pin(48), 1)

# Wi-Fi credentials
SSID = "Muath"
PASSWORD = "Camry1423"

# Setup SPI and RFID reader
spi = SPI(2, baudrate=1000000, polarity=0, phase=0,
          sck=Pin(12), mosi=Pin(11), miso=Pin(13))
rdr = MFRC522(spi=spi, gpio_rst=Pin(14), gpio_cs=Pin(10))

# Connect to Wi-Fi
def connect_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    if not wlan.isconnected():
        print("Connecting to Wi-Fi...")
        wlan.connect(SSID, PASSWORD)
        while not wlan.isconnected():
            time.sleep(0.5)
    print("Connected. IP:", wlan.ifconfig()[0])

# Firebase update URL
FIREBASE_BASE_URL = "https://rfid-scan-demo-default-rtdb.europe-west1.firebasedatabase.app/scans.json"

# Update Firebase with custom payload
def update_firebase(status, card_id, station_number):
    try:
        url = f"{FIREBASE_BASE_URL}"
        payload = {
            f"bus_station_{station_number}": {
                "status": status,
                "card_id": card_id
            }
        }
        headers = {"Content-Type": "application/json"}
        res = urequests.patch(url, data=ujson.dumps(payload), headers=headers)
        print(f"✅ Firebase updated | Station: {station_number} | Status: {status} | Card ID: {card_id}")
        res.close()
    except Exception as e:
        print("❌ Firebase error:", e)

# Main logic
def run():
    connect_wifi()
    print("Ready to scan RFID cards...")

    card_present = False  # Track whether a card is currently present

    while True:
        (stat, tag_type) = rdr.request(rdr.REQIDL)
        if stat == rdr.OK:
            (stat, raw_uid) = rdr.anticoll()
            if stat == rdr.OK:
                uid = "{:02x}{:02x}{:02x}{:02x}".format(*raw_uid)

                if not card_present:
                    # Only send when new card is detected
                    print("Card detected:", uid)
                    update_firebase(status=1, card_id=uid)
                    card_present = True

                # Light up GREEN
                np[0] = (0, 255, 0)
                np.write()
                time.sleep(0.3)
                np[0] = (0, 0, 0)
                np.write()

                # Wait until card is removed
                while True:
                    stat, _ = rdr.request(rdr.REQIDL)
                    if stat != rdr.OK:
                        print("Card removed.")
                        update_firebase(status=0, card_id="")
                        card_present = False
                        break
                    time.sleep(0.2)

        # RED heartbeat LED
        np[0] = (255, 0, 0)
        np.write()
        time.sleep(0.1)

# Start the program
run()
