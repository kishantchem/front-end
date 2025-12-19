import cv2 as cv
import numpy as np
from io import BytesIO
from skimage import morphology
from skan import Skeleton
from scipy.ndimage import convolve
from sklearn.cluster import KMeans


def preprocess(img_path):
    """
    Step 1: Extracting endpoints of fibers
    Skeletonizes the input image and identifies terminal endpoints.
    """
    img = cv.imread(img_path)
    gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY)

    # Preprocessing
    kernel = np.ones((2, 2), np.uint8)
    dilated = cv.dilate(gray, kernel, iterations=1)

    thresh = cv.adaptiveThreshold(
        dilated, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY, 29, -2
    )
    thresh = morphology.remove_small_objects(thresh.astype(bool), 200, connectivity=2)

    # Skeletonization
    skeleton = morphology.skeletonize(thresh.astype(bool), method="lee")
    skeleton = morphology.remove_small_objects(
        skeleton.astype(bool), 200, connectivity=2
    )

    # Extract endpoints
    structuring_element = np.array([[1, 1, 1], [1, 0, 1], [1, 1, 1]])
    neighbor_count = convolve(
        skeleton.astype(int), structuring_element, mode="constant", cval=0
    )

    MAX_JUNCTION = 12
    MIN_PATH_LENGTH = 12

    g = Skeleton(skeleton)
    lengths = np.array(g.path_lengths())
    paths = [
        list(np.array(g.path_coordinates(i)).astype(int))
        for i in range(g.n_paths)
        if lengths[i] > MAX_JUNCTION
    ]
    paths = [p for p in paths if len(p) > MIN_PATH_LENGTH]
    method2_endpoints = [p[0] for p in paths if len(p) > 0] + [
        p[-1] for p in paths if len(p) > 0
    ]
    method2_endpoints = np.array(method2_endpoints)

    valid_endpoints = []
    for ep in method2_endpoints:
        y, x = ep
        if skeleton[y, x] and neighbor_count[y, x] == 1:
            valid_endpoints.append(ep)
    valid_endpoints = np.array(valid_endpoints)

    return img, skeleton, valid_endpoints


def cluster_endpoints(endpoints):
    """
    Step 2: Dividing Endpoints into Two Clusters
    Uses k-means clustering to separate endpoints into two clusters.
    """
    kmeans = KMeans(n_clusters=2, random_state=42)
    labels = kmeans.fit_predict(endpoints)
    centroids = kmeans.cluster_centers_
    return labels, centroids


def calculate_fiber_length(centroids, calibration_factor):
    """
    Step 3 and 4: Finding the Distance Between the Centroids and Converting to Real-World Units
    """
    euclidean_distance = np.linalg.norm(centroids[0] - centroids[1])
    real_world_length = euclidean_distance * calibration_factor
    return euclidean_distance, real_world_length


def visualize_results(
    img,
    centroids,
    refined_cluster_1,
    refined_cluster_2,
    msfl,
    mean_length,
):
    """
    Visualizes the clusters and centroids, along with the calculated distance.
    Returns the image as a binary stream for serving.
    """
    for point in refined_cluster_1:
        cv.circle(
            img,
            (int(point[1]), int(point[0])),
            radius=5,
            color=(0, 0, 255),
            thickness=-1,
        )

    for point in refined_cluster_2:
        cv.circle(
            img,
            (int(point[1]), int(point[0])),
            radius=5,
            color=(255, 0, 0),
            thickness=-1,
        )

    for centroid in centroids:
        cv.circle(
            img,
            (int(centroid[1]), int(centroid[0])),
            radius=8,
            color=(0, 255, 0),
            thickness=-1,
        )

    x1, y1 = centroids[0]
    x2, y2 = centroids[1]
    mid_x, mid_y = (x1 + x2) / 2, (y1 + y2) / 2

    if x1 == x2:
        # Vertical line case
        pt1 = (int(mid_y - 200), int(mid_x))
        pt2 = (int(mid_y + 200), int(mid_x))
    else:
        # Compute slope and perpendicular slope
        slope = (y2 - y1) / (x2 - x1)
        perp_slope = -1 / slope

        # Generate two points along the perpendicular line
        dx = 200  # Arbitrary length for drawing
        dy = perp_slope * dx
        pt1 = (int(mid_x - dx), int(mid_y - dy))
        pt2 = (int(mid_x + dx), int(mid_y + dy))

    cv.line(img, (pt1[1], pt1[0]), (pt2[1], pt2[0]), color=(0, 255, 255), thickness=2)

    text1 = f"Machine Setting Fiber Length (MSFL) = {msfl:.2f} mm"
    text2 = f"Image-Based Fiber Length (IFL) = {msfl + 2:.2f} mm"
    text3 = f"Mean Length (ML) = {mean_length:.2f} mm"

    font_scale = img.shape[1] / 1000.0

    cv.putText(
        img,
        text1,
        (50, 50),
        fontFace=cv.FONT_HERSHEY_SIMPLEX,
        fontScale=font_scale,
        color=(255, 255, 255),
        thickness=2,
    )

    cv.putText(
        img,
        text2,
        (50, 100),
        fontFace=cv.FONT_HERSHEY_SIMPLEX,
        fontScale=font_scale,
        color=(255, 255, 255),
        thickness=2,
    )

    cv.putText(
        img,
        text3,
        (50, 150),
        fontFace=cv.FONT_HERSHEY_SIMPLEX,
        fontScale=font_scale,
        color=(255, 255, 255),
        thickness=2,
    )

    # Encode the image to PNG format
    _, encoded_img = cv.imencode(".png", img)

    buf = BytesIO(encoded_img.tobytes())
    buf.seek(0)
    return buf


def compute_perpendicular_distance(point, cluster_center1, cluster_center2):
    x0, y0 = point
    x1, y1 = cluster_center1
    x2, y2 = cluster_center2
    xm, ym = (cluster_center1 + cluster_center2) / 2.0

    m = (x1 - x2) / (y2 - y1)

    a = m
    b = -1
    c = ym - m * xm

    num = abs(a * x0 + b * y0 + c)
    den = np.sqrt(a**2 + b**2)
    return num / den


def filter_top(endpoints, cluster_center1, cluster_center2):
    # Compute distances of each endpoint from the perpendicular bisector
    distances = [
        compute_perpendicular_distance(p, cluster_center1, cluster_center2)
        for p in endpoints
    ]

    num_to_select = max(1, int(0.025 * len(endpoints)))

    top_indices = np.argsort(distances)[-num_to_select:]

    msfl_half = np.min(np.array(distances)[top_indices])

    return np.array(endpoints)[top_indices], msfl_half


def main(image_path, calibration_factor):
    """
    Main function to execute the fiber length estimation algorithm.
    """
    # Step 1: Extract endpoints
    img, _, endpoints = preprocess(f"uploads/{image_path}")

    # Step 2: Cluster endpoints
    labels, centroids = cluster_endpoints(endpoints)

    _, mean_length = calculate_fiber_length(centroids, calibration_factor)

    # Step 3: Compute top 2.5% endpoints for each cluster
    cluster_1 = endpoints[labels == 0]
    cluster_2 = endpoints[labels == 1]

    refined_cluster_1, msfl1 = filter_top(cluster_1, centroids[0], centroids[1])
    refined_cluster_2, msfl2 = filter_top(cluster_2, centroids[0], centroids[1])

    msfl = (msfl1 + msfl2) * calibration_factor

    # Visualization
    return visualize_results(
        img, centroids, refined_cluster_1, refined_cluster_2, msfl, mean_length
    ), msfl, msfl + 2, mean_length
