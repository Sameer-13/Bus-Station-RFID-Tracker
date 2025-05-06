from machine import Pin, SPI
from mfrc522 import MFRC522
import neopixel
import network
import urequests
import ujson
import time

# RGB LED setup (GPIO48 = onboard WS2812)
np = neopixel.NeoPixel(Pin(48), 1)

# Wi-Fi credentials
SSID = "Muath"
PASSWORD = "Camry1423"

# Firebase URL
FIREBASE_URL = "https://rfid-scan-demo-default-rtdb.europe-west1.firebasedatabase.app/scans.json"

# SPI + RFID setup (confirmed working pins on SPI(1))
spi = SPI(1, baudrate=1000000, polarity=0, phase=0,
          sck=Pin(6), mosi=Pin(7), miso=Pin(8))
rdr = MFRC522(spi=spi, gpio_rst=Pin(9), gpio_cs=Pin(5))

# Connect to Wi-Fi
def connect_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    if not wlan.isconnected():
        print("Connecting to Wi-Fi...")
        wlan.connect(SSID, PASSWORD)
        while not wlan.isconnected():
            time.sleep(0.5)
    print("✅ Wi-Fi connected:", wlan.ifconfig()[0])

# Send UID and status to Firebase
def update_firebase(status, card_id, station_number=1):
    try:
        payload = {
            f"bus_station_{station_number}": {
                "status": status,
                "card_id": card_id
            }
        }
        headers = {"Content-Type": "application/json"}
        res = urequests.patch(FIREBASE_URL, data=ujson.dumps(payload), headers=headers)
        print(f"✅ Firebase updated | Station {station_number} | Status: {status} | UID: {card_id}")
        res.close()
    except Exception as e:
        print("❌ Firebase error:", e)

def run():
    connect_wifi()
    print("Ready to scan RFID cards...")

    last_uid = None
    card_lost_time = None

    while True:
        (stat, tag_type) = rdr.request(rdr.REQIDL)
        if stat == rdr.OK:
            (stat, raw_uid) = rdr.anticoll()
            if stat == rdr.OK:
                uid = "{:02x}{:02x}{:02x}{:02x}".format(*raw_uid)

                # New card detected
                if uid != last_uid:
                    print("📟 New card:", uid)
                    update_firebase(status=1, card_id=uid)
                    last_uid = uid

                    # Green LED flash
                    np[0] = (0, 255, 0)
                    np.write()
                    time.sleep(0.3)
                    np[0] = (0, 0, 0)
                    np.write()

                # Reset loss timer if card is still there
                card_lost_time = None
        else:
            # Card might be removed
            if last_uid is not None:
                now = time.ticks_ms()
                if card_lost_time is None:
                    card_lost_time = now
                elif time.ticks_diff(now, card_lost_time) > 1000:
                    print("💨 Card removed.")
                    update_firebase(status=0, card_id="")
                    last_uid = None
                    card_lost_time = None

        # Red heartbeat if no card
        if last_uid is None:
            np[0] = (255, 0, 0)
            np.write()
            time.sleep(0.05)
            np[0] = (0, 0, 0)
            np.write()
            time.sleep(0.05)
        else:
            time.sleep(0.1)
# Run it
run()

