import json
import urllib2
import requests


def update_inventory(item_id):
    patch_url = 'https://hackvalley-5be01.firebaseio.com/inventories/{id}/.json'

    json_response = get_item_inventory(item_id)

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


def get_item_inventory(item_id):
    url = 'https://hackvalley-5be01.firebaseio.com/inventories/{id}/item_count.json'

    response = urllib2.urlopen(url.format(id=item_id)).read()
    return json.loads(response)
