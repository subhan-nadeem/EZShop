#!/usr/local/bin/python

import RPi.GPIO as GPIO
import threading
import time
import requests
import urllib2
import json

GPIO.setmode(GPIO.BOARD)

# define the pin that  goes to the circuit
PIN_1_CIRCUIT = 7
PIN_2_CIRCUIT = 29
PIN_3_CIRCUIT = 31

DARK = 40000
LIGHT = 0
REFRESH_RATE = 0.05

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


def update_inventory(item_id):
    url = 'https://hackvalley-5be01.firebaseio.com/inventories/{id}/item_count.json'
    patch_url = 'https://hackvalley-5be01.firebaseio.com/inventories/{id}/.json'

    response = urllib2.urlopen(url.format(id=item_id)).read()
    json_response = json.loads(response)

    if json_response > 0:
        json_response -= 1

        req = urllib2.Request(patch_url.format(id=item_id))
        req.add_header('Content-Type', 'application/json')
        req.add_header('type', 'PATCH')

        data = json.dumps({'item_count': json_response})

        requests.patch(patch_url.format(id=item_id), data)
        print "Decremented inventory for item: {item}. {num} remaining.".format(item=item_id, num=json_response)
    else:
        print "Inventory of item {item} did not change. {num} remaining.".format(item=item_id, num=json_response)


def update_events(item_id):
    patch_url = 'https://hackvalley-5be01.firebaseio.com/events/.json'

    data = json.dumps({
        'item_id': item_id,
        'status': 'in_cart'
    })

    requests.post(patch_url, data)
    print "Updated events for item: {item}".format(item=item_id)


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


# thread1 = myThread(PIN_1_CIRCUIT)
thread2 = MyThread(PIN_2_CIRCUIT)
# thread3 = MyThread(PIN_3_CIRCUIT)

# thread1.start()
thread2.start()
#thread3.start()
