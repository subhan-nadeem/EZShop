#!/usr/local/bin/python

import RPi.GPIO as GPIO
import threading
import time
from InventoryClient import *
import json

GPIO.setmode(GPIO.BOARD)

# define the pin that  goes to the circuit
PIN_1_CIRCUIT = 7
PIN_2_CIRCUIT = 29
PIN_3_CIRCUIT = 31

DARK = 40000
LIGHT = 0
REFRESH_RATE = 0.1

item_map = {
    PIN_1_CIRCUIT: 1,
    PIN_2_CIRCUIT: 2,
    PIN_3_CIRCUIT: 3
}

item_status = {
    PIN_1_CIRCUIT: True,
    PIN_2_CIRCUIT: True,
    PIN_3_CIRCUIT: True
}


class MyThread(threading.Thread):
    def __init__(self, pin_to_circuit):
        threading.Thread.__init__(self)
        self.pin_to_circuit = pin_to_circuit

    def run(self):
        try:
            while True:
                rc_time(self.pin_to_circuit)
        except KeyboardInterrupt:
            pass
        finally:
            GPIO.cleanup()


def rc_time(pin_to_circuit):
    count = 0

    # Output on the pin for
    GPIO.setup(pin_to_circuit, GPIO.OUT)
    GPIO.output(pin_to_circuit, GPIO.LOW)
    time.sleep(REFRESH_RATE)

    # Change the pin back to input
    GPIO.setup(pin_to_circuit, GPIO.IN)

    # Count until the pin goes high
    while GPIO.input(pin_to_circuit) == GPIO.LOW:
        count += 1

    print "Sensor: " + str(pin_to_circuit) + " value: " + str(count)

    if LIGHT < count < DARK:
        if item_status[pin_to_circuit]:
            item_status[pin_to_circuit] = False
            # update_inventory(item_map[pin_to_circuit])
            # update_events(item_map[pin_to_circuit])
            print "id: {0} is taken".format(item_map[pin_to_circuit])

    else:
        print "Dark {0} count {1}".format(item_map[pin_to_circuit], count)
        item_status[pin_to_circuit] = True


thread1 = MyThread(PIN_1_CIRCUIT)
# thread2 = MyThread(PIN_2_CIRCUIT)
# thread3 = MyThread(PIN_3_CIRCUIT)

thread1.start()
# thread2.start()
# thread3.start()
