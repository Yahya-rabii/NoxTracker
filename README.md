# NOXTRACKER

![App Demo](demo.png)

This Flutter project demonstrates how to integrate the Google Maps API to track users and get their live location. The app allows users to see their current location on the map in real-time.

## Features

- Display a map with the user's current location.
- Continuously update the user's location on the map.
- Customize the map appearance and markers.
- Add additional functionality to interact with the map, such as adding markers, geocoding, etc.

## Screenshots

![Screenshot 1](screenshots/screenshot1.png)
![Screenshot 2](screenshots/screenshot2.png)

## Getting Started

To run this project locally, follow these steps:

### Prerequisites

- Flutter SDK: [Installation Guide](https://flutter.dev/docs/get-started/install)
- Google Maps API key: [Obtaining an API Key](https://developers.google.com/maps/documentation/javascript/get-api-key)

### Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/your-username/your-repository.git
   Navigate to the project directory:
      cd your-repository
   Replace YOUR_API_KEY in lib/main.dart with your Google Maps API key:
      static const String MAPS_API_KEY = 'YOUR_API_KEY';
   Install the required dependencies:
      flutter pub get
   Run the app:
      flutter run
### Configuration
    You can customize various aspects of the app by modifying the following parameters in lib/main.dart:

    MAPS_API_KEY: Your Google Maps API key.
    Map appearance: Zoom level, initial location, map type, etc.
    Marker customization: Icon, color, size, etc.
    
### Contributing
    Contributions are welcome! If you find any issues or would like to contribute enhancements or new features, feel free to open a pull request. Please ensure that your changes     adhere to the existing code style and conventions.
### License
    This project is licensed under the MIT License.
    
Make sure to replace the placeholders (`YOUR_API_KEY`, `your-username`, `your-repository`, etc.) with your actual values. Additionally, you can add your own screenshots to the `screenshots` directory and update the image paths accordingly in the README.

      

