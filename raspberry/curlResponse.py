# some kind of authenticatin or a secret here
import json
import urllib2
import requests

url = 'https://hackvalley-5be01.firebaseio.com/inventories/2/item_count.json'
patch_url = 'https://hackvalley-5be01.firebaseio.com/inventories/2/.json'

item_id = 2

response = urllib2.urlopen(url.format(id=item_id)).read()
json_response = json.loads(response)
json_response -= 1

req = urllib2.Request(patch_url.format(id=item_id))
req.add_header('Content-Type', 'application/json')
req.add_header('type', 'PATCH')

data = json.dumps({'item_count': json_response})

response = requests.patch(patch_url.format(id=item_id), data)
