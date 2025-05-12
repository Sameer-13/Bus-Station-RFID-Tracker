# Bus Station Status Tracking System

A real-time bus station tracking system built with Flutter (mobile app) and ESP32 microcontrollers with RFID readers. This system allows users to monitor the status of bus stations on a map and tracks when RFID cards are scanned at each station.

## System Overview

This project consists of two main components:

1. **Mobile Application**: A Flutter app that displays a map with the status of each bus station, updating in real-time.
2. **ESP32 RFID Stations**: Physical stations with ESP32 microcontrollers and RFID readers that detect when cards are scanned.

Data is synchronized through Firebase Realtime Database, allowing for instant updates between the hardware stations and the mobile app.

## Application Overveiw:
![WhatsApp Image 2025-05-12 at 19 04 58_428799a7](https://github.com/user-attachments/assets/79523b8f-e97f-4245-827a-61a670acfd53)
![WhatsApp Image 2025-05-12 at 19 04 57_9543047b](https://github.com/user-attachments/assets/0f760d45-f1c9-4e28-880f-9e56d092c6d4)


## Features

- Real-time status updates of bus stations
- Interactive map showing all bus stations
- Color-coded markers (green = active, red = inactive)
- RFID card detection at physical stations
- Automatic status changes when cards are scanned or removed
- Visual feedback using RGB LEDs on the ESP32 devices

## Requirements

### Mobile App

- Flutter SDK 3.2.1 or higher
- Dependencies:
  - flutter_map: ^6.0.0
  - latlong2: ^0.9.0
  - http: ^1.1.0

### ESP32 Hardware

- ESP32 development board (with onboard WS2812 RGB LED)
- MFRC522 RFID reader module
- MicroPython firmware with the following modules:
  - machine
  - neopixel
  - network
  - urequests
  - ujson
  - time

## Setup Instructions

### Setting up the ESP32 Stations

1. Flash MicroPython firmware to your ESP32 board
2. Connect the MFRC522 RFID reader to the ESP32 using these pins:
   - SCK: GPIO6
   - MOSI: GPIO7
   - MISO: GPIO8
   - RST: GPIO9
   - CS: GPIO5

3. Upload the following files to the ESP32:
   - `mfrc522.py`: RFID reader library
   - `main.py` or `bus2.py` (depending on which station you're setting up)

4. Adjust the Wi-Fi credentials in the script:
   ```python
   SSID = "YourNetworkName"
   PASSWORD = "YourPassword"
   ```

5. Update the Firebase URL if needed:
   ```python
   FIREBASE_URL = "https://your-firebase-project.firebasedatabase.app/scans.json"
   ```

6. Set the correct station number in the `update_firebase()` function:
   - `main.py` uses station_number=1
   - `bus2.py` uses station_number=2
   - For additional stations, create new files with different station numbers

### Setting up the Flutter App

1. Make sure Flutter is installed on your development machine
2. Clone this repository
3. Navigate to the project directory and run:
   ```
   flutter pub get
   ```

4. If you need to modify the Firebase URL, update it in `lib/main.dart`:
   ```dart
   final response = await http.get(
     Uri.parse('https://your-firebase-project.firebasedatabase.app/scans.json'),
   );
   ```

5. If you need to add or modify the bus station locations, update the `busStations` list in `lib/main.dart`

6. Run the app:
   ```
   flutter run
   ```

## Usage

### ESP32 Station Operation

1. Power on the ESP32 device - it will automatically connect to Wi-Fi
2. When no card is present, the RGB LED will blink red
3. When an RFID card is scanned, the LED will flash green and then turn off
4. The station status will be updated in Firebase
5. When a card is removed, after a 1-second delay, the status will be updated to inactive

### Mobile App Operation

1. Launch the app to see the map with all bus stations
2. Each station appears as a marker:
   - Red: Inactive (no card present)
   - Green: Active (card present)
3. Tap on a marker to see details about the station, including:
   - Station name
   - Status
   - Card ID (if a card is present)
4. Use the refresh button to manually update the status (though updates happen automatically every second)
5. Use the location button to fit all markers on the screen

## Project Structure

```
bus_station_tracker/
├── esp32/
│   ├── main.py          # Code for Station 1
│   ├── bus2.py          # Code for Station 2
│   └── mfrc522.py       # RFID reader library
├── lib/
│   └── main.dart        # Flutter app code
├── data/
│   └── sample.json      # Sample data structure
└── pubspec.yaml         # Flutter dependencies
```

## Firebase Data Structure

The Firebase Realtime Database stores status data in the following format:

```json
{
    "bus_station_1": {
        "status": 1,
        "card_ID": "1234567890"
    },
    "bus_station_2": {
        "status": 0,
        "card_ID": "None"
    },
    "bus_station_3": {
        "status": 1,
        "card_ID": "0987654321"
    }
}
```

## Troubleshooting

### ESP32 Issues
- If the ESP32 fails to connect to Wi-Fi, check your credentials and network status
- If RFID detection is inconsistent, verify the wiring connections to the RFID module
- If the LED doesn't work, ensure that it's connected to the correct pin (GPIO48)

### Flutter App Issues
- If the app fails to load data, check your internet connection and Firebase URL
- If the map doesn't display, ensure you have an active internet connection for tile loading
- If markers don't update, try manually refreshing or restarting the app

## License

This project is licensed under the MIT License.

## Contributors

- Sameer Alsabea (Sameer-13),[Linked in](https://www.linkedin.com/in/sameer-alsabea-610291239/)

- Muath Alsubhi (63G), [Linked in](https://www.linkedin.com/in/muath-alsubhi/)

## Acknowledgments

- OpenStreetMap for providing the map tiles
- Flutter Map package for the map implementation
- Firebase for the real-time database
