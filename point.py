# Sorting algorithm adapted from https://stackoverflow.com/questions/2855189/sort-latitude-and-longitude-coordinates-into-clockwise-ordered-quadrilateral/2863378#2863378

from math import sqrt
from functools import cmp_to_key

class Point:
    def __init__(self, lat, lng):
        self.lat = lat
        self.lng = lng
        self.x = (lng + 180) * 360
        self.y = (lat + 90) * 180

    def distance(self, other):
        dx = other.x - self.x
        dy = other.y - self.y
        return sqrt((dx**2) + (dy**2))
    

    def slope(self, other):
        dx = other.x - self.x
        dy = other.y - self.y
        return dy / dx if dx != 0 else 0

    def to_json(self):
        return {"lat": self.lat, "lng": self.lng}


class Sorter:
    def __init__(self, points):
        self.points = points
        self.upper = Sorter.upper_left(points)

    @staticmethod
    def upper_left(points):
        top = points[0]
        for point in points[1:]:
            if point.y > top.y or (point.y == top.y and point.x < top.x):
                top = point

        return top

    def _point_sort(self, p1, p2):
        if p1 == self.upper: return -1
        if p2 == self.upper: return 1

        m1 = self.upper.slope(p1)
        m2 = self.upper.slope(p2)

        if m1 == m2:
            return (-1 if p1.distance(self.upper) < p2.distance(self.upper) else 1)

        if m1 <= 0 and m2 > 0: return -1

        if m1 > 0 and m2 <= 0: return 1

        return -1 if m1 > m2 else 1

    def sorted(self):
        return sorted(self.points, key=cmp_to_key(self._point_sort))