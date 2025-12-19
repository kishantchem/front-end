import numpy as np
import cv2 as cv
from skan import Skeleton
from skimage import graph, morphology
from scipy.spatial.distance import euclidean

MAX_JUNCTION = 10  # maximal size of junctions
MAX_ANGLE = 80  # maximal angle in junction
DELTA = 5  # distance from endpoint to inner point to estimate direction at endpoint
MIN_PATH_LENGTH = 30  # minimal length of path to be considered as thread
BRIGHTNESS_THRESHOLD = (
    128  # minimum mean intensity to consider background white and fibers black
)


def angle(v1, v2):
    rad = np.arctan2(v2[0], v2[1]) - np.arctan2(v1[0], v1[1])
    return np.abs((np.rad2deg(rad) % 360) - 180)


def calculate_path_length(path):
    """Calculate the length of a path given its coordinates"""
    length = 0
    for i in range(1, len(path)):
        length += euclidean(path[i - 1], path[i])
    return length


def segment_threads(filename: str):
    """Segment threads and return their lengths"""
    # Load and preprocess image
    img = cv.imread(f"uploads/{filename}")

    # Convert the image into grayscale
    gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY)
    
    # Invert the grayscale image if needed
    _, otsu_thresh = cv.threshold(gray, 0, 255, cv.THRESH_BINARY + cv.THRESH_OTSU)
    if np.mean(otsu_thresh) >= BRIGHTNESS_THRESHOLD:
        gray = 255 - gray
    
    # Dilate and threshold
    kernel = np.ones((2, 2), np.uint8)
    dilated = cv.dilate(gray, kernel, iterations=1)
    
    # Apply adaptive thresholding to handle non-uniform lighting
    thresh = cv.adaptiveThreshold(dilated, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY, 11, -2)
    thresh = morphology.remove_small_objects(thresh.astype(bool), 200, connectivity=2)
    thresh = thresh.astype(np.uint8) * 255
    thresh = cv.dilate(thresh, kernel, iterations=3)
    
    # Skeletonize
    skeleton = morphology.skeletonize(thresh.astype(bool), method="lee")
    skeleton = morphology.remove_small_objects(skeleton.astype(bool), 200, connectivity=2)
    skeleton = skeleton.astype(np.uint8) * 255
    # closing
    skeleton = cv.morphologyEx(skeleton, cv.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    skeleton = cv.morphologyEx(skeleton, cv.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    skeleton = cv.morphologyEx(skeleton, cv.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    skeleton = morphology.remove_small_objects(skeleton.astype(bool), 200, connectivity=2)

    # Split skeleton into paths, for each path longer than MAX_JUNCTION get list of point coordinates
    g = Skeleton(skeleton)
    lengths = np.array(g.path_lengths())
    paths = [
        list(np.array(g.path_coordinates(i)).astype(int))
        for i in range(g.n_paths)
        if lengths[i] > MAX_JUNCTION
    ]

    # Get endpoints of path and vector to inner point to estimate direction at endpoint
    endpoints = [
        [p[0], np.subtract(p[0], p[DELTA]), i] for i, p in enumerate(paths)
    ] + [[p[-1], np.subtract(p[-1], p[-1 - DELTA]), i] for i, p in enumerate(paths)]

    # Get each pair of distinct endpoints with the same junction and calculate deviation of angle
    angles = []
    costs = np.where(skeleton, 1, 255)  # cost array for route_through_array

    for i1 in range(len(endpoints)):
        for i2 in range(i1 + 1, len(endpoints)):
            e1, d1, p1 = endpoints[i1]
            e2, d2, p2 = endpoints[i2]
            if p1 != p2:
                p, c = graph.route_through_array(
                    costs, e1, e2
                )  # check connectivity of endpoints at junction
                if c <= MAX_JUNCTION:
                    deg = angle(d1, d2)  # get deviation of directions at junction
                    if deg <= MAX_ANGLE:
                        angles.append((deg, i1, i2, p))

    # Merge paths, with least deviation of angle first
    angles.sort(key=lambda a: a[0])

    for deg, i1, i2, p in angles:
        e1, e2 = endpoints[i1], endpoints[i2]
        if e1 and e2:
            p1, p2 = e1[2], e2[2]
            paths[p1] = (
                paths[p1] + paths[p2] + p
            )  # merge path 2 into path 1, add junction from route_through_array
            for i, e in enumerate(
                endpoints
            ):  # switch path 2 at other endpoint to new merged path 1
                if e and e[2] == p2:
                    endpoints[i][2] = p1
            paths[p2], endpoints[i1], endpoints[i2] = (
                [],
                [],
                [],
            )  # disable merged path and endpoints

    filtered_paths = [p for p in paths if len(p) > MIN_PATH_LENGTH]

    path_lengths = [calculate_path_length(path) for path in filtered_paths]

    return [filename, path_lengths]
