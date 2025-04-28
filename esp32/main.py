from machine import Pin, SPI
from mfrc522 import MFRC522
import neopixel
import network
import urequests
import ujson
import time

np = neopixel.NeoPixel(Pin(48), 1)
# 🔧 Wi-Fi credentials
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


FIREBASE_URL = "https://rfid-scan-demo-default-rtdb.europe-west1.firebasedatabase.app/scans.json"
# Send UID to webhook.site
def send_uid_to_firebase(uid):
    try:
        payload = {
            "uid": uid,
            "timestamp": time.time()
        }
        headers = {"Content-Type": "application/json"}
        res = urequests.post(FIREBASE_URL, data=ujson.dumps(payload), headers=headers)
        print("✅ Sent to Firebase:", res.status_code)
        res.close()
    except Exception as e:
        print("❌ Firebase error:", e)

# Main logic
def run():
    connect_wifi()
    
    np = neopixel.NeoPixel(Pin(48), 1)  # Initialize RGB LED
    print("Ready to scan RFID cards...")
    while True:
        
        (stat, tag_type) = rdr.request(rdr.REQIDL)
        if stat == rdr.OK:
            (stat, raw_uid) = rdr.anticoll()
            if stat == rdr.OK:
                uid = "{:02x}{:02x}{:02x}{:02x}".format(*raw_uid)
                print("Card detected:", uid)

                # Send UID
                send_uid_to_firebase(uid)

                # Light up GREEN
                np[0] = (0, 255, 0)
                np.write()
                time.sleep(0.3)
                np[0] = (0, 0, 0)
                np.write()

                # Wait until card is removed before next read
                while True:
                    stat, _ = rdr.request(rdr.REQIDL)
                    if stat != rdr.OK:
                        break
                    time.sleep(0.2)  # Debounce delay

        np[0] = (255, 0, 0)
        np.write()
        time.sleep(0.1)

        
# Run everything
run()


