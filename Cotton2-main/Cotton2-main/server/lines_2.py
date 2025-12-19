import cv2
import numpy as np
from skimage.morphology import skeletonize, remove_small_objects
from skan import draw, Skeleton, summarize
from skan.csr import skeleton_to_csgraph
from matplotlib import pyplot as plt

def read_image(file_path):
    """Read the input image."""
    return cv2.imread(file_path)

def show_image(title, image):
    """Display the image using matplotlib."""
    plt.imshow(image, cmap='gray')
    plt.title(title)
    plt.show()

def preprocess_image(image):
    """Preprocess the input image (grayscale, filter, etc.)."""

    # Convert the image to grayscale
    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Dilates the grayscale image. Dilation adds pixels to the boundaries of the object.
    filtered_image = cv2.dilate(gray_image, np.ones((2, 2), np.uint8), iterations=1)

    # Pixels with intensity value greater than or equal to 25 are set to 255 (white)
    # Pixels with intensity value less than 100 are set to 0 (black)
    _, binary_image = cv2.threshold(filtered_image, 25, 255, cv2.THRESH_BINARY)

    # Scales the pixel values of the binary image. 0 pixel value remains 0 and 255 pixel value is scaled to 1.
    # Only two pixel values: 0 means black and 1 means white.
    binary_image = (binary_image / 255).astype(np.uint8)

    return gray_image, binary_image

def skeletonize_image(binary_image):
    """Skeletonize the binary image using Lee's method."""
    # Skeletonization reduces binary objects to 1 pixel wide representations.
    # skeletonize works by making successive passes of the image. On each pass, border pixels
    # are identified and removed on the condition that they don't break the connectivity of the object.
    # Refer https://scikit-image.org/docs/stable/auto_examples/edges/plot_skeleton.html
    skeleton = skeletonize(binary_image, method='lee')

    # Removes small objects from skeleton image (having total number of pixels less than 10).
    # Connectivity = 2 means that all the 8-surrounding pixels are to be considered while calcualting size.
    skeleton = remove_small_objects(skeleton, 10, connectivity=2)

    return skeleton

def analyze_skeleton(skeleton, spacing_nm, original_image):
    """Analyze the skeleton and extract branch data."""
    # Pixel graph is the sparse matrix in which entry (i,j) is 0 if pixels i and j are not connected.
    # Otherwise, it is the distance between pixels i and j.
    # The distance is 1 between adjacent pixels and Sqrt(2) between diagonally adjacent pixels.
    # Second variable (coordinates) contains the coordinates (in pixel units) of the white pixels.
    pixel_graph, coordinates = skeleton_to_csgraph(skeleton, spacing=spacing_nm)
    skel_analysis = Skeleton(skeleton, spacing=spacing_nm, source_image=original_image)
    coordinates = skel_analysis.coordinates

    # branch distance is the sum of distances along the path nodes between two nodes.
    # Brach type: 0 - endpoint to endpoint , 1 - junction to endpoint , 2 - junction to junction
    # Junction pixel means - 3 or more adjacent pixels are white
    # Endpoint pixel means - only 1 adjacent pixel can be white
    # Path pixel means - 2 adjacent pixels white

    # Refer https://skeleton-analysis.org/stable/getting_started/getting_started.html#measuring-the-length-of-skeleton-branches
    branch_data = summarize(skel_analysis)

    return branch_data, coordinates

def measure_fiber_length(branch_data, binary_image, min_length_threshold):
    """Measure the length of fibers and print statistics."""

    # Filters the paths that are longer than specified minimum length threshold.
    long_fibers = branch_data[branch_data['branch-distance'] > min_length_threshold]

    # Calculates statistical measures for the lengths of the long fibers (for analysis only)
    count, mean_length, stdev_length = long_fibers['branch-distance'].describe().loc[['count', 'mean', 'std']]

    print(f"Fiber Length (px): Count: {int(count)}, Average: {round(mean_length, 2)}, Std Dev: {round(stdev_length, 2)}")

    # Print individual lengths of the long fibers (for analysis only)
    print("Individual Fiber Lengths:")
    for idx, length in enumerate(long_fibers['branch-distance']):
        print(f"Fiber {idx + 1}: {round(length, 2)} pixels")

    return long_fibers

def fiber_length_2(image_path):

    # Read and preprocess the image
    original_image = read_image(image_path)

    gray_image, binary_image = preprocess_image(original_image)

    # Skeletonize the binary image
    skeleton = skeletonize_image(binary_image)

    # Analyze the skeleton and extract branch data
    spacing_nm = 1   # pixel
    branch_data, coordinates = analyze_skeleton(skeleton, spacing_nm, original_image)

    # Measure the length of fibers and print statistics
    min_length = 10  # threshold to remove small length fibers (potential noise)
    long_fibers = measure_fiber_length(branch_data, binary_image, min_length)

    # Visualize results
    fig, ax = plt.subplots()
    draw.overlay_skeleton_2d(gray_image, skeleton, dilate=1, axes=ax)
    # # plt.show()

    node_ids = long_fibers[['node-id-src', 'node-id-dst']].values.flatten()
    long_fiber_coords = coordinates[node_ids]
    fiber_lengths = long_fibers['branch-distance'].values

    # Plot long fibers on the original image and annotate with length values
    for i in range(len(long_fiber_coords) // 2):
        src = long_fiber_coords[2 * i]
        dst = long_fiber_coords[2 * i + 1]
        length = fiber_lengths[i]

        ax.plot([src[1], dst[1]], [src[0], dst[0]], 'ro-')  # Assuming coordinates[0] is y and coordinates[1] is x
        ax.text((src[1] + dst[1]) / 2, (src[0] + dst[0]) / 2, f'{length:.2f}', color='blue', fontsize=8, ha='center', va='center')

    plt.show()

    return [image_path, fiber_lengths]
