import json
import requests


def update_events(item_id):
    patch_url = 'https://hackvalley-5be01.firebaseio.com/events/.json'

    data = json.dumps({
        'item_id': item_id,
        'status': 'in_cart'
    })

    requests.post(patch_url, data)

    print "Updated events for item: {item}".format(item=item_id)

update_events(2)
