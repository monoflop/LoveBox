#!/usr/bin/python

# pip install Pillow

import sys, getopt
import array
import base64
import math
from PIL import Image

DISPLAY_WIDTH = 128
DISPLAY_HEIGHT = 64

#TODO check if image has alpha channel
COLOR_WHITE = (255, 255, 255, 255)
COLOR_BLACK = (0, 0, 0, 255)

def printUsage():
    print("usage: bitmapGenerator.py (--type -t {base64|cpp}) (-image -i <IMAGE_FILE>) [--rle -r] [--verbose -v]\n\t--verbose -v : enable verbose output\n\t--rle -r : enable run length encoding")

def set_bit(value, bit):
    return value | (1<<(bit))

def main():
    #Parse arguments
    input_file = ""
    type = ""
    verbose = False
    rle = False

    try:
        opts, args = getopt.getopt(sys.argv[1:],"vrt:i:",["verbose", "rle", "type=","image="])
    except getopt.GetoptError as err:
        print(err)
        printUsage()
        sys.exit()
    for opt, arg in opts:
        if opt in ("-v", "--verbose"):
            verbose = True
        if opt in ("-r", "--rle"):
            rle = True
        if opt in ("-t", "--type"):
            type = arg
        elif opt in ("-i", "--image"):
            input_file = arg

    #Check if valid
    if(type != "base64" and type != "cpp"):
        printUsage()
        sys.exit()

    #Try to open provided image file
    im = Image.open(input_file)
    input_image = im.load()

    #Check dimensions
    if(im.size[0] != DISPLAY_WIDTH or im.size[1] != DISPLAY_HEIGHT):
        print("Invalid dimensions " + str(im.size))
        sys.exit()

    #Image is encoded as following
    #White pixel = lit pixel = set bit
    bitmap = array.array('B', [0] * int((DISPLAY_WIDTH * DISPLAY_HEIGHT) / 8.0))

    #Iterate over image file
    whiteCount = 0
    unknownColor = 0
    for y in range(im.height):
        for x in range(im.width):
            #Calculate target byte
            byte_index = int((y * DISPLAY_WIDTH + x) / 8)

            #Calculate target bit
            bit_index = int((y * DISPLAY_WIDTH + x) % 8)
            bit_index = 7 - bit_index

            #Set bit according to image pixel color
            if(input_image[x, y] == COLOR_WHITE):
                whiteCount = whiteCount + 1
                bitmap[byte_index] = set_bit(bitmap[byte_index], bit_index)
            elif (input_image[x, y] != COLOR_BLACK):
                unknownColor = unknownColor + 1

    #Apply rle
    #Max run length possible is 128x64 = 8192
    #We need at least 13 bits but we use 16 and start with 0
    #if the encoded array is larger than unencoded bitmap, we return the bitmap
    #on decoding we can check the full length e.g 8192 = unencoded

    #better format: we check the longest sequence first and decide block length based on that
    #block length is encoded in first 16 bits
    #TODO complete
    blocks = 0
    zero_bits = True
    max_bit_count = 0
    bit_count = 0
    if(rle):
        #Iterate over bytes
        for byte in range(len(bitmap)):
            #Iterate over bits
            for bit in reversed(range(1, 9)):
                check_num=bitmap[byte]>>(bit-1)
                #print("checking bit " +  str(bit-1) + " of byte {0:b}".format(bitmap[byte]) + " " + str((check_num&1)!=0))
                if ((check_num&1)!=0):
                    #set
                    if zero_bits:
                        #start new block
                        #Write bitcount TODO
                        print("bits changed to zero_bits = false: block with 0 count: " + str(bit_count))
                        zero_bits = False
                        if(bit_count > max_bit_count):
                            max_bit_count = bit_count
                        bit_count = 1
                        blocks = blocks + 1
                    else:
                        #add to count
                        bit_count = bit_count + 1
                else:
                    #not set
                    if zero_bits:
                        #add to count
                        bit_count = bit_count + 1
                    else:
                        #start new block
                        #Write bitcount TODO
                        print("bits changed to zero_bits = true: block with 1 count: " + str(bit_count))
                        zero_bits = True
                        if(bit_count > max_bit_count):
                            max_bit_count = bit_count
                        bit_count = 1
                        blocks = blocks + 1
        block_size = int(int(math.sqrt(max_bit_count) / 8) * 8)
        print("max block length " + str(max_bit_count) + " block size: " + str(block_size) + " bits")
        print("block count: " + str(blocks))
        print("encoded size: " + str((16 + blocks * block_size)))

    #Convert byte array to base64
    if(type == "base64"):
        bitmapBase64 = base64.b64encode(bitmap)
        print(bitmapBase64.decode('utf-8'))
    elif(type == "cpp"):
        output = "uint8_t FRAME[] = {"
        body = ""
        for b in range(len(bitmap)):
            body = body + hex(bitmap[b]) + ","

        body = body[0:len(body) - 1]
        output = output + body + "};"
        print(output)

    if(verbose):
        print("\nWhite pixels " + str(whiteCount))
        print("Unknown color pixels " + str(unknownColor))

if __name__ == "__main__":
    main()