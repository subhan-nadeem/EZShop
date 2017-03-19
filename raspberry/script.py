#!/usr/local/bin/python

import RPi.GPIO as GPIO
import threading
import time

GPIO.setmode(GPIO.BOARD)

# define the pin that  goes to the circuit
pin_1_to_circuit = 7
pin_2_to_circuit = 29
pin_3_to_circuit = 31

dark = 70000
light = 0

refresh_rate = 0.1

item_map = {
    pin_1_to_circuit: 1,
    pin_2_to_circuit: 2,
    pin_3_to_circuit: 3
}

item_status = {
    pin_1_to_circuit: True,
    pin_2_to_circuit: True,
    pin_3_to_circuit: True
}

class myThread (threading.Thread):
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
    
    if (json_response > 0):
        json_reponse -= 1

        req = urllib2.Request(patch_url.format(id=item_id))
        req.add_header('Content-Type', 'application/json')
        req.add_header('type', 'PATCH')

        data = json.dumps({'item_count': json_response})

        requests.patch(patch_url.format(id=item_id), data)
        print "Decremented inventory for item: {item}. {num} remaining.".format(item=item_id, num=json_reponse)
    else:
        print "Inventory of item {item} did not change. {num} remaining.".format(item=item_id, num=json_response)


def rc_time(pin_to_circuit):
    count = 0
    prev_status = item_status[pin_to_circuit]
    
    # Output on the pin for
    GPIO.setup(pin_to_circuit, GPIO.OUT)
    GPIO.output(pin_to_circuit, GPIO.LOW)
    time.sleep(refresh_rate)

    # Change the pin back to input
    GPIO.setup(pin_to_circuit, GPIO.IN)

    # Count until the pin goes high
    while GPIO.input(pin_to_circuit) == GPIO.LOW:
        count += 1


    # print "Sensor: " + str(pin_to_circuit) + " value: " + str(count)
    
    if light < count < dark:
        print "Light {0} count: {1}".format(item_map[pin_to_circuit], count)
        if (item_status[pin_to_circuit]):
            item_status[pin_to_circuit] = False
            # update_inventory(item_map[pin_to_circuit])
            print "id: {0} is taken. count {1}".format(item_map[pin_to_circuit], count)

    else:
        print "Dark {0} count {1}".format(item_map[pin_to_circuit], count)
        item_status[pin_to_circuit] = True


#thread1 = myThread(pin_1_to_circuit)
thread2 = myThread(pin_2_to_circuit)
#thread3 = myThread(pin_3_to_circuit)

#thread1.start()
thread2.start()
#thread3.start()
