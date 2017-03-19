# Libraries
import RPi.GPIO as GPIO
import time
from InventoryClient import *
import math

# GPIO Mode (BOARD / BCM)
GPIO.setmode(GPIO.BCM)

# set GPIO Pins
GPIO_TRIGGER = 18
GPIO_ECHO = 24

BOTTLE_SIZE = 6 # cm
MARGIN_ERR = 2  # cm
EMPTY_D = 60  # cm
ITEM_ID = 2
REFERSH_RATE = 2  # seconds

# set GPIO direction (IN / OUT)
GPIO.setup(GPIO_TRIGGER, GPIO.OUT)
GPIO.setup(GPIO_ECHO, GPIO.IN)


def distance_changed():

    GPIO.output(GPIO_TRIGGER, True)

    time.sleep(0.00001)
    GPIO.output(GPIO_TRIGGER, False)

    start_time = time.time()
    stop_time = time.time()

    while GPIO.input(GPIO_ECHO) == 0:
        start_time = time.time()

    while GPIO.input(GPIO_ECHO) == 1:
        stop_time = time.time()

    time_elapsed = stop_time - start_time

    d = (time_elapsed * 34300) / 2
    
    num_bottles = ((EMPTY_D - d) / BOTTLE_SIZE)

    return int(math.floor(abs(num_bottles)))


if __name__ == '__main__':
    item_load = get_item_inventory(ITEM_ID)
    
    try:
        while True:
            items = distance_changed()
            if item_load != items:
                update_inventory(ITEM_ID)
                update_events(ITEM_ID)
                item_load = items
                print items

            time.sleep(REFERSH_RATE)

    except KeyboardInterrupt:
        print("Measurement stopped by User")
        GPIO.cleanup()
