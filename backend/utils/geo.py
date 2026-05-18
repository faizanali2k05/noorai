import math

# Area centroids — used when the user doesn't share GPS coords
AREA_CENTROIDS = {
    ("Lahore", "Gulberg"): (31.5204, 74.3587),
    ("Lahore", "DHA"): (31.4707, 74.4036),
    ("Lahore", "Johar Town"): (31.4697, 74.2728),
    ("Lahore", "Model Town"): (31.4837, 74.3225),
    ("Karachi", "Clifton"): (24.8138, 67.0299),
    ("Karachi", "DHA"): (24.8004, 67.0648),
    ("Karachi", "Gulshan"): (24.9180, 67.0971),
    ("Karachi", "North Nazimabad"): (24.9326, 67.0379),
    ("Islamabad", "F-8"): (33.7077, 73.0563),
    ("Islamabad", "F-10"): (33.7000, 73.0277),
    ("Islamabad", "F-11"): (33.6892, 73.0156),
    ("Islamabad", "G-9"): (33.6932, 73.0479),
    ("Islamabad", "G-10"): (33.6852, 73.0245),
    ("Islamabad", "G-13"): (33.6500, 72.9500),
}

# Rough city centroids as fallback if area unknown
CITY_CENTROIDS = {
    "Lahore": (31.5204, 74.3587),
    "Karachi": (24.8607, 67.0011),
    "Islamabad": (33.6844, 73.0479),
}


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in km between two (lat, lng) points."""
    r = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def resolve_user_location(city: str | None, area: str | None,
                          user_lat: float | None = None, user_lng: float | None = None
                          ) -> tuple[float, float] | None:
    if user_lat is not None and user_lng is not None:
        return (user_lat, user_lng)
    if city and area and (city, area) in AREA_CENTROIDS:
        return AREA_CENTROIDS[(city, area)]
    if city and city in CITY_CENTROIDS:
        return CITY_CENTROIDS[city]
    return None
