# import the necessary packages
from PIL import Image
import numpy as np
import argparse
import glob
import cv2
 
def auto_canny(image,sigma):
	# compute the median of the single channel pixel intensities
	v = np.median(image)
	print "sigma %f" % sigma
	print "median %f" % v
	# apply automatic Canny edge detection using the computed median
	lower = int(max(0, (1.0 - sigma) * v))
	upper = int(min(255, (1.0 + sigma) * v))
	edged = cv2.Canny(image, lower, upper)
	# return the edged image
	return edged
      
# construct the argument parse and parse the arguments
ap = argparse.ArgumentParser()
ap.add_argument("-i", "--input", required=True,
	help="path to input image")
ap.add_argument("-o", "--output", required=True,
	help="path to output image")
ap.add_argument("-s", "--sig", type=int , required=True,
	help="sigma value")
ap.add_argument("-u", "--upper", type=float , required=True,
                help="upper value")
ap.add_argument("-l", "--lower", type=float , required=True,
                help="lower value")
args = vars(ap.parse_args())
# load the images
input_image = cv2.imread(args["input"])
sig = args["sig"]
lower = args["lower"]
upper = args["upper"]
output_image = cv2.imread(args["output"])
# load the image, convert it to grayscale, and blur it slightly
gray = cv2.cvtColor(input_image, cv2.COLOR_BGR2GRAY)
blurred = cv2.GaussianBlur(gray, (sig, sig), 0)
# apply Canny edge detection using a wide threshold, tight
# threshold, and automatically determined threshold
#auto = auto_canny(gray,sig)
auto = cv2.Canny(blurred,lower,upper)
if args["output"] is not None:
	cv2.imwrite(args["output"], auto)
