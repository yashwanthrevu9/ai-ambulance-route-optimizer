# AI Emergency Ambulance Route Optimizer

An emergency response prototype designed to help identify suitable hospitals and visualize ambulance routes using mapping and routing technologies.

## Features

- **Emergency Decision Support:** Combines emergency details, route scoring, and hospital selection.
- **Hospital Selection:** Evaluates prototype hospital data, including distance, available beds, and ICU availability.
- **Route Optimization:** Compares routes using factors such as travel time, distance, and traffic penalties.
- **Interactive Map:** Displays road routes using OpenStreetMap.
- **Ambulance Movement Simulation:** Animates an ambulance marker along the selected route.
- **Journey Completion:** Displays a message when the simulated ambulance reaches the hospital.

## Technologies Used

- Flutter and Dart
- Python and FastAPI
- OpenStreetMap
- OSRM Routing API
- REST API

## Project Structure

```text
AI Ambulance Route Optimizer/
├── main.py
├── .gitignore
└── ambulance_app/
    ├── lib/
    │   └── main.dart
    ├── pubspec.yaml
    └── android/
```

## Getting Started

### Backend Setup

1. Install Python.
2. Create and activate a virtual environment.
3. Install the required Python packages.
4. Start the FastAPI server:

```bash
uvicorn main:app --reload
```

5. Open `http://127.0.0.1:8000/docs` to explore the API.

### Flutter Setup

1. Install Flutter and configure the Android development environment.
2. Open the `ambulance_app` folder.
3. Install dependencies:

```bash
flutter pub get
```

4. Start the application:

```bash
flutter run
```

## Current Limitations

This is a prototype. Hospital availability and route-scoring inputs may use sample data. Ambulance movement is simulated rather than based on live GPS tracking. Live traffic feeds and real hospital-system integrations are not implemented.

The public OSRM routing service is used for demonstration and is not guaranteed for production emergency use.

## Future Enhancements

- Live traffic and road-closure integration
- Real-time hospital bed availability
- GPS-based ambulance tracking
- Voice navigation and emergency notifications
- Improved AI-based route ranking

## Disclaimer

This project is intended for educational and demonstration purposes only. It is not a certified emergency dispatch or navigation system.
