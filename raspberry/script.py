#!/usr/local/bin/python

import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BOARD)

#define the pin that  goes to the circuit
pin_1_to_circuit = 7
pin_2_to_circuit = 29
dark = 20000
light = 0
refresh_rate = 0.3

def rc_time (pin_to_circuit):
    count = 0
  
    #Output on the pin for 
    GPIO.setup(pin_to_circuit, GPIO.OUT)
    GPIO.output(pin_to_circuit, GPIO.LOW)
    time.sleep(refresh_rate)

    #Change the pin back to input
    GPIO.setup(pin_to_circuit, GPIO.IN)
  
    #Count until the pin goes high
    while (GPIO.input(pin_to_circuit) == GPIO.LOW):
        count += 1

    if (count > light and count < dark):
        return str(pin_to_circuit) + ' light'
    else:
        return str(pin_to_circuit) + ' dark'


#Catch when script is interrupted, cleanup correctly
try:
    # Main loop
    while True:
        print rc_time(pin_1_to_circuit)
        print rc_time(pin_2_to_circuit)
except KeyboardInterrupt:
    pass
finally:
    GPIO.cleanup()
