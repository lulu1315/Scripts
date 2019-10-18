# import the necessary packages
from PIL import Image
import numpy as np
import argparse
import glob
import cv2

# construct the argument parse and parse the arguments
ap = argparse.ArgumentParser()
ap.add_argument("-i", "--input", required=True,
	help="path to input image")
args = vars(ap.parse_args())
# load the images
input_image = cv2.imread(args["input"])
# load the image, convert it to grayscale, and blur it slightly
gray = cv2.cvtColor(input_image, cv2.COLOR_BGR2GRAY)
#compute median value
#v = np.median(gray)
v = np.average(gray)
#print "median %f" % v
print (v)
