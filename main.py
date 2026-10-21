from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(
    title="AI Emergency Ambulance Route Optimizer",
    description="AI-powered ambulance routing and hospital selection system",
    version="1.0.0"
)


class EmergencyRequest(BaseModel):
    ambulance_location: str
    hospital_location: str
    emergency_level: str


@app.get("/")
def home():
    return {
        "message": "AI Ambulance Route Optimizer API is running",
        "status": "success"
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy"
    }
@app.get("/hospitals")
def get_hospitals():
    return {
        "hospitals": [
            {
                "name": "Government General Hospital",
                "location": "Bhimavaram",
                "available_beds": 12,
                "emergency_available": True,
                "icu_available": 5
            },
            {
                "name": "Vijaya Hospital",
                "location": "Bhimavaram",
                "available_beds": 7,
                "emergency_available": True,
                "icu_available": 2
            },
            {
                "name": "City Care Hospital",
                "location": "Bhimavaram",
                "available_beds": 0,
                "emergency_available": False,
                "icu_available": 0
            }
        ]
    }
@app.post("/select-hospital")
def select_hospital(request: EmergencyRequest):

    hospitals = [
        {
            "name": "Government General Hospital",
            "location": "Bhimavaram",
            "available_beds": 12,
            "emergency_available": True,
            "icu_available": 5,
            "distance_km": 3.2
        },
        {
            "name": "Vijaya Hospital",
            "location": "Bhimavaram",
            "available_beds": 7,
            "emergency_available": True,
            "icu_available": 2,
            "distance_km": 4.5
        },
        {
            "name": "City Care Hospital",
            "location": "Bhimavaram",
            "available_beds": 0,
            "emergency_available": False,
            "icu_available": 0,
            "distance_km": 2.8
        }
    ]

    for hospital in hospitals:

        score = 0

        if hospital["emergency_available"]:
            score += 50

        score += hospital["icu_available"] * 5
        score += hospital["available_beds"] * 2

        # Lower distance is better
        score -= hospital["distance_km"] * 2

        if request.emergency_level.lower() == "critical":
            if hospital["icu_available"] > 0:
                score += 20

        hospital["score"] = round(score, 2)

    available_hospitals = [
        hospital
        for hospital in hospitals
        if hospital["emergency_available"]
        and hospital["available_beds"] > 0
    ]

    if not available_hospitals:
        return {
            "message": "No suitable hospital available",
            "recommended_hospital": None,
            "hospitals": hospitals
        }

    best_hospital = max(
        available_hospitals,
        key=lambda hospital: hospital["score"]
    )

    return {
        "emergency_level": request.emergency_level,
        "ambulance_location": request.ambulance_location,
        "recommended_hospital": best_hospital,
        "available_hospitals": available_hospitals,
        "decision": {
            "method": "AI hospital suitability scoring",
            "factors": [
                "Emergency availability",
                "ICU availability",
                "Available beds",
                "Distance",
                "Emergency severity"
            ]
        }
    }

@app.post("/optimize-route")
def optimize_route(request: EmergencyRequest):

    routes = [
        {
            "route": "Route A",
            "distance_km": 8.2,
            "estimated_time_min": 18,
            "traffic": "Low"
        },
        {
            "route": "Route B",
            "distance_km": 6.7,
            "estimated_time_min": 22,
            "traffic": "High"
        },
        {
            "route": "Route C",
            "distance_km": 9.1,
            "estimated_time_min": 20,
            "traffic": "Medium"
        }
    ]

    traffic_penalty = {
        "Low": 0,
        "Medium": 10,
        "High": 25
    }

    for route in routes:

        route["score"] = (
            route["estimated_time_min"]
            + route["distance_km"]
            + traffic_penalty[route["traffic"]]
        )

    if request.emergency_level.lower() == "critical":

        for route in routes:
            route["score"] += traffic_penalty[route["traffic"]]

    best_route = min(
        routes,
        key=lambda route: route["score"]
    )

    return {
        "emergency_level": request.emergency_level,
        "ambulance_location": request.ambulance_location,
        "hospital_location": request.hospital_location,
        "available_routes": routes,
        "recommended_route": best_route,
        "decision": {
            "method": "AI route scoring",
            "factors": [
                "Estimated travel time",
                "Distance",
                "Traffic",
                "Emergency severity"
            ]
        }
    }
@app.post("/emergency-decision")
def emergency_decision(request: EmergencyRequest):

    # Route data
    routes = [
        {
            "route": "Route A",
            "distance_km": 8.2,
            "estimated_time_min": 18,
            "traffic": "Low"
        },
        {
            "route": "Route B",
            "distance_km": 6.7,
            "estimated_time_min": 22,
            "traffic": "High"
        },
        {
            "route": "Route C",
            "distance_km": 9.1,
            "estimated_time_min": 20,
            "traffic": "Medium"
        }
    ]

    traffic_penalty = {
        "Low": 0,
        "Medium": 10,
        "High": 25
    }

    for route in routes:
        route["score"] = (
            route["estimated_time_min"]
            + route["distance_km"]
            + traffic_penalty[route["traffic"]]
        )

    if request.emergency_level.lower() == "critical":
        for route in routes:
            route["score"] += traffic_penalty[route["traffic"]]

    best_route = min(routes, key=lambda route: route["score"])

    # Hospital data
    hospitals = [
        {
            "name": "Government General Hospital",
            "location": "Bhimavaram",
            "available_beds": 12,
            "emergency_available": True,
            "icu_available": 5,
            "distance_km": 3.2
        },
        {
            "name": "Vijaya Hospital",
            "location": "Bhimavaram",
            "available_beds": 7,
            "emergency_available": True,
            "icu_available": 2,
            "distance_km": 4.5
        },
        {
            "name": "City Care Hospital",
            "location": "Bhimavaram",
            "available_beds": 0,
            "emergency_available": False,
            "icu_available": 0,
            "distance_km": 2.8
        }
    ]

    for hospital in hospitals:
        score = 0

        if hospital["emergency_available"]:
            score += 50

        score += hospital["icu_available"] * 5
        score += hospital["available_beds"] * 2
        score -= hospital["distance_km"] * 2

        if request.emergency_level.lower() == "critical":
            if hospital["icu_available"] > 0:
                score += 20

        hospital["score"] = round(score, 2)

    available_hospitals = [
        hospital
        for hospital in hospitals
        if hospital["emergency_available"]
        and hospital["available_beds"] > 0
    ]

    best_hospital = max(
        available_hospitals,
        key=lambda hospital: hospital["score"]
    )

    return {
        "emergency_level": request.emergency_level,
        "recommended_route": best_route,
        "recommended_hospital": best_hospital,
        "decision": {
            "method": "Combined AI emergency decision",
            "factors": [
                "Route travel time",
                "Distance",
                "Traffic",
                "Hospital bed availability",
                "ICU availability",
                "Emergency severity"
            ]
        }
    }