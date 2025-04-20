from machine import Pin, SPI
from mfrc522 import MFRC522
import time
# Code to read UIDs of RFID tags
spi = SPI(2, baudrate=1000000, polarity=0, phase=0,
          sck=Pin(12), mosi=Pin(11), miso=Pin(13))
rdr = MFRC522(spi=spi, gpio_rst=Pin(14), gpio_cs=Pin(10))

print("Ready to scan...")

last_uid = None
card_present = False

while True:
    (stat, tag_type) = rdr.request(rdr.REQIDL)
    if stat == rdr.OK:
        (stat, raw_uid) = rdr.anticoll()
        if stat == rdr.OK:
            uid = "{:02x}{:02x}{:02x}{:02x}".format(*raw_uid)
            
            if not card_present or uid != last_uid:
                print("Card detected. UID:", uid)
                last_uid = uid
                card_present = True
    else:
        # No card present — reset state
        card_present = False
        last_uid = None

    time.sleep(0.1)

