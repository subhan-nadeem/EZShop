# Libraries
import RPi.GPIO as GPIO
import time
from InventoryClient import *

# GPIO Mode (BOARD / BCM)
GPIO.setmode(GPIO.BCM)

# set GPIO Pins
GPIO_TRIGGER = 18
GPIO_ECHO = 24

BOTTLE_SIZE = 6  # cm
MARGIN_ERR = 2  # cm
EMPTY_D = 58  # cm
ITEM_ID = 2
REFERSH_RATE = 1  # seconds

# set GPIO direction (IN / OUT)
GPIO.setup(GPIO_TRIGGER, GPIO.OUT)
GPIO.setup(GPIO_ECHO, GPIO.IN)


def distance_changed(initial_load):

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
    num_bottles = (EMPTY_D - d) / BOTTLE_SIZE

    if num_bottles > 0:
        if num_bottles != initial_load:
            print "Number of bottles has changed {0}->{1}".format(
                initial_load, num_bottles)
    else:
        print "There are currently {0} bottles".format(num_bottles)

    return item_load


if __name__ == '__main__':
    item_load = get_item_inventory(ITEM_ID)

    try:
        while True:
            new_load = distance_changed(item_load)
            if new_load != item_load:
                update_events(ITEM_ID)
                update_inventory(ITEM_ID)

            time.sleep(REFERSH_RATE)

            # Reset by pressing CTRL + C
    except KeyboardInterrupt:
        print("Measurement stopped by User")
        GPIO.cleanup()
