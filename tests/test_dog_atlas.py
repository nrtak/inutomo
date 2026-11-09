import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from dog_atlas_bounds import subject_bounds


class AlphaPlane:
    def __init__(self, width, height, points):
        self.width, self.height = width, height
        self.size = (width, height)
        self.points = points

    def crop(self, cell):
        left, top, right, bottom = cell
        return AlphaPlane(right-left,bottom-top,
            {(x-left,y-top) for x,y in self.points if left<=x<right and top<=y<bottom})

    def getchannel(self, channel):
        assert channel == 'A'
        return self

    def tobytes(self):
        return bytes(255 if (x,y) in self.points else 0
            for y in range(self.height) for x in range(self.width))


class DogAtlasBoundsTests(unittest.TestCase):
    def silhouette(self, width, height, points):
        return AlphaPlane(width,height,points)

    def test_neighbor_tail_and_previous_row_paws_are_excluded(self):
        body = {(x,y) for x in range(4,12) for y in range(6,16)}
        fragments = {(x,1) for x in range(6,12)} | {(18,y) for y in range(9,15)}
        image = self.silhouette(20,20,body|fragments)
        self.assertEqual(subject_bounds(image,(0,0,20,20)),(2,4,14,18))

    def test_diagonally_connected_tail_stays_in_frame(self):
        body = {(x,y) for x in range(6,12) for y in range(6,14)}
        tail = {(3,3),(4,4),(5,5)}
        image = self.silhouette(20,20,body|tail)
        self.assertEqual(subject_bounds(image,(0,0,20,20)),(1,1,14,16))

    def test_padding_never_crosses_cell_boundaries(self):
        image = self.silhouette(20,20,{(x,y) for x in range(8,20) for y in range(5,17)})
        self.assertEqual(subject_bounds(image,(8,5,20,17)),(0,0,12,12))

    def test_empty_cell_is_rejected(self):
        with self.assertRaises(ValueError):
            subject_bounds(self.silhouette(20,20,set()),(0,0,20,20))

    def test_tail_crossing_nominal_column_is_preserved(self):
        body = {(x,y) for x in range(12,18) for y in range(6,15)}
        tail = {(x,9) for x in range(8,13)}
        neighbor = {(x,y) for x in range(3,7) for y in range(2,17)}
        image = self.silhouette(20,20,body|tail|neighbor)
        self.assertEqual(subject_bounds(image,(10,0,20,20),horizontal_overflow=7),(-4,4,10,17))


if __name__ == '__main__':
    unittest.main()
