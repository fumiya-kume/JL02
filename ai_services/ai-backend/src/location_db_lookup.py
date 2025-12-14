"""
Location-Based Tourist Spots Database Lookup Module

This module provides functionality to load and query a tourist spots database
based on latitude and longitude coordinates. It's designed to be location-agnostic
and can work with any regional tourist database.
"""

import json
import math
import os
from pathlib import Path
from typing import Optional, Dict, Any, List


class LocationDBLookup:
    """Lookup nearest tourist spot based on latitude and longitude."""

    def __init__(self, db_path: Optional[str] = None):
        """
        Initialize LocationDBLookup with the database file.

        Args:
            db_path: Path to tourist spots database JSON file. If None, searches for it in the project root.
        """
        if db_path is None:
            # Search for database file in parent directories
            current_path = Path(__file__).parent
            # Try common database locations
            for parent in [current_path.parent.parent.parent, *current_path.parents]:
                for db_name in ["GinzaDB", "LocationDB", "TouristSpotsDB"]:
                    for file_name in [
                        f"{db_name.lower()}.json",
                        "locations.json",
                        "spots.json",
                    ]:
                        potential_path = parent / db_name / file_name
                        if potential_path.exists():
                            db_path = str(potential_path)
                            break
                if db_path:
                    break
            else:
                raise FileNotFoundError(
                    "Could not find tourist spots database file. Please provide explicit path."
                )

        self.db_path = db_path
        self.spots = self._load_database()
        self._default_top_k = int(os.getenv("LOCATION_TOP_K", 5))

    def _load_database(self) -> List[Dict[str, Any]]:
        """Load tourist spots from JSON file."""
        with open(self.db_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        # Support multiple database formats
        # Look for common keys that might contain the spots data
        for key in ["tourist_spots", "ginza_tourist_spots", "locations", "spots"]:
            if key in data:
                return data[key]

        # If not found, assume the root is an array or return empty list
        if isinstance(data, list):
            return data
        return []

    @staticmethod
    def _haversine_distance(
        lat1: float, lon1: float, lat2: float, lon2: float
    ) -> float:
        """
        Calculate the great circle distance between two points on Earth (in kilometers).

        Uses the Haversine formula for accurate distance calculation.

        Args:
            lat1, lon1: First point coordinates (degrees)
            lat2, lon2: Second point coordinates (degrees)

        Returns:
            Distance in kilometers
        """
        R = 6371  # Earth's radius in kilometers

        # Convert to radians
        lat1_rad = math.radians(lat1)
        lat2_rad = math.radians(lat2)
        delta_lat = math.radians(lat2 - lat1)
        delta_lon = math.radians(lon2 - lon1)

        # Haversine formula
        a = (
            math.sin(delta_lat / 2) ** 2
            + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        distance = R * c

        return distance

    def find_nearest(
        self, latitude: float, longitude: float
    ) -> Optional[Dict[str, Any]]:
        """
        Find the nearest tourist spot to given coordinates.

        Args:
            latitude: User's latitude
            longitude: User's longitude

        Returns:
            Dictionary containing the nearest spot's information, or None if no spots found
        """
        if not self.spots:
            return None

        nearest_spot = None
        min_distance = float("inf")

        for spot in self.spots:
            distance = self._haversine_distance(
                latitude,
                longitude,
                spot["latitude"],
                spot["longitude"],
            )

            if distance < min_distance:
                min_distance = distance
                nearest_spot = spot

        # Add distance to the result
        if nearest_spot:
            nearest_spot = dict(nearest_spot)  # Create a copy
            nearest_spot["distance_km"] = round(min_distance, 3)

        return nearest_spot

    def find_nearby(
        self, latitude: float, longitude: float, radius_km: float = 1.0
    ) -> List[Dict[str, Any]]:
        """
        Find all tourist spots within a given radius.

        Args:
            latitude: User's latitude
            longitude: User's longitude
            radius_km: Search radius in kilometers (default: 1.0 km)

        Returns:
            List of spots within the radius, sorted by distance
        """
        nearby_spots = []

        for spot in self.spots:
            distance = self._haversine_distance(
                latitude,
                longitude,
                spot["latitude"],
                spot["longitude"],
            )

            if distance <= radius_km:
                spot_with_distance = dict(spot)  # Create a copy
                spot_with_distance["distance_km"] = round(distance, 3)
                nearby_spots.append(spot_with_distance)

        # Sort by distance
        nearby_spots.sort(key=lambda x: x["distance_km"])

        return nearby_spots

    def get_spot_by_name(self, name: str) -> Optional[Dict[str, Any]]:
        """
        Find a tourist spot by name (case-insensitive partial match).

        Args:
            name: Name of the spot to search for

        Returns:
            The matching spot, or None if not found
        """
        name_lower = name.lower()
        for spot in self.spots:
            if name_lower in spot["name"].lower():
                return spot
        return None

    def get_all_spots(self) -> List[Dict[str, Any]]:
        """
        Get all tourist spots.

        Returns:
            List of all tourist spots
        """
        return self.spots.copy()

    def find_top_k(
        self, latitude: float, longitude: float, k: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Find the top-k nearest tourist spots to given coordinates.

        Args:
            latitude: User's latitude
            longitude: User's longitude
            k: Number of spots to return. If None, uses LOCATION_TOP_K environment variable
              (default: 5)

        Returns:
            List of top-k nearest spots, sorted by distance
        """
        if k is None:
            k = self._default_top_k
        if not self.spots:
            return []

        spots_with_distance = []

        for spot in self.spots:
            distance = self._haversine_distance(
                latitude,
                longitude,
                spot["latitude"],
                spot["longitude"],
            )
            spot_with_distance = dict(spot)  # Create a copy
            spot_with_distance["distance_km"] = round(distance, 3)
            spots_with_distance.append(spot_with_distance)

        # Sort by distance and return top-k
        spots_with_distance.sort(key=lambda x: x["distance_km"])
        return spots_with_distance[:k]
